# app/controllers/dossier/cv_variants_controller.rb

# The signed-in user's CV Variants (My CVs › CV Variants): tailored CVs picked
# from the master data. New takes copy_from (one of your variants) to fill the
# form from it; creating with Copy From set also copies its ticks.
class Dossier::CvVariantsController < ApplicationController
  include Navigable
  include Dossier::CvDownloadable
  before_action :require_dossier_access, only: %i[index new create]
  before_action :set_variant, except: %i[index new create]
  before_action :require_read, only: %i[show pdf docx]
  before_action :require_update, only: %i[edit update selection update_selection reset_selection]
  before_action :require_profile, only: %i[pdf docx]

  SELECTABLE = %w[engagement assignment achievement skill credential].freeze

  helper_method :copy_choices

  def index
    @variants = current_user.dossier_cv_variants.alphabetical
  end

  # Settings, what's included, and the downloads.
  def show
    @cv = cv
  end

  def pdf  = send_cv_pdf(cv)
  def docx = send_cv_docx(cv)

  def new
    original = copy_choices.find_by(id: params[:copy_from])
    @variant = if original
      Dossier::CvVariant.copy_from(original, name: "#{original.name} (Copy)")
    else
      current_user.dossier_cv_variants.build
    end
  end

  def create
    original = copy_choices.find_by(id: params.dig(:dossier_cv_variant, :based_on_id))
    attributes = variant_params.to_h.symbolize_keys
    @variant = if original
      Dossier::CvVariant.copy_from(original, **attributes)
    else
      current_user.dossier_cv_variants.build(attributes)
    end
    if @variant.save
      toast_created(@variant)
      redirect_to @variant
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    previous_label = @variant.to_toast_label
    if @variant.update(variant_params)
      toast_updated(@variant, previous_label: previous_label)
      redirect_to @variant
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Edit Selection: a checkbox per Engagement, Assignment, Achievement, Skill
  # and Credential of the variant's owner, ticked as the variant has them.
  def selection
    load_selectable
  end

  def update_selection
    load_selectable
    ticks = SELECTABLE.flat_map do |kind|
      submitted = params.dig(:selection, kind) || {}
      @selectable[kind].filter_map { |record| [ record, submitted[record.id.to_s] == "1" ] if submitted.key?(record.id.to_s) }
    end
    @selection.save!(ticks)
    redirect_to @variant, flash: { success: "#{@variant.name}'s selection has been saved" }
  end

  def reset_selection
    @variant.items.delete_all
    redirect_to @variant, flash: { success: "#{@variant.name} is back to the default selection" }
  end

  def destroy
    unless Policy.new(current_user, @variant).can_delete?
      redirect_to dossier_cv_variants_path, alert: "Not authorised." and return
    end
    @variant.destroy
    toast_deleted(@variant)
    redirect_to dossier_cv_variants_path
  end

  private

  # The owner's records, for the page and to check submitted ids against.
  def load_selectable
    owner = @variant.user
    @selection = Dossier::CvSelection.new(@variant)
    @engagements = owner.dossier_engagements.kept.newest_first
                        .includes(:employer, :employment_type, assignments: [ :client, :role, :achievements ]).to_a
    skills = Dossier::ExperienceCalculator.new(owner).skills.map(&:skill)
    ActiveRecord::Associations::Preloader.new(records: skills, associations: :skill_category).call
    @skill_groups = skills.group_by(&:skill_category).sort_by { |category, _| category.name.downcase }
    credentials = owner.dossier_credentials.kept.newest_first.includes(:credential_type).to_a
    @credential_groups = credentials.group_by(&:credential_type).sort_by { |type, _| [ type.position, type.name.downcase ] }

    assignments = @engagements.flat_map(&:assignments)
    @selectable = { "engagement" => @engagements, "assignment" => assignments,
                    "achievement" => assignments.flat_map(&:achievements), "skill" => skills, "credential" => credentials }
  end

  # The owner's CV through this variant (an Admin downloads the owner's CV).
  def cv
    @cv ||= Dossier::CvDocument.new(@variant.user, variant: @variant)
  end

  def require_read
    redirect_to dossier_cv_variants_path, alert: "Not authorised." unless Policy.new(current_user, @variant).can_read?
  end

  def require_profile
    redirect_to edit_dossier_profile_path, alert: NO_PROFILE unless cv.profile?
  end

  def require_update
    redirect_to dossier_cv_variants_path, alert: "Not authorised." unless Policy.new(current_user, @variant).can_update?
  end

  def copy_choices
    current_user.dossier_cv_variants.alphabetical
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_variant
    @variant = Dossier::CvVariant.find(params[:id])
  end

  def variant_params
    params.require(:dossier_cv_variant).permit(:name, :target_company, :target_role, :job_description, :voice, :style,
                                               :summary_override, :show_tech_stack, :min_importance)
  end
end
