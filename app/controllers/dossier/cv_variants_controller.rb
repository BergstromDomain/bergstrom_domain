# app/controllers/dossier/cv_variants_controller.rb

# The signed-in user's CV Variants (My CVs › CV Variants): tailored CVs picked
# from the master data. New takes copy_from (one of your variants) to fill the
# form from it; creating with Copy From set also copies its ticks.
class Dossier::CvVariantsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[index new create]
  before_action :set_variant, only: %i[show edit update destroy]

  helper_method :copy_choices

  def index
    @variants = current_user.dossier_cv_variants.alphabetical
  end

  def show
    redirect_to dossier_cv_variants_path, alert: "Not authorised." unless Policy.new(current_user, @variant).can_read?
  end

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
    redirect_to dossier_cv_variants_path, alert: "Not authorised." unless Policy.new(current_user, @variant).can_update?
  end

  def update
    unless Policy.new(current_user, @variant).can_update?
      redirect_to dossier_cv_variants_path, alert: "Not authorised." and return
    end
    previous_label = @variant.to_toast_label
    if @variant.update(variant_params)
      toast_updated(@variant, previous_label: previous_label)
      redirect_to @variant
    else
      render :edit, status: :unprocessable_entity
    end
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

  def copy_choices
    current_user.dossier_cv_variants.alphabetical
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_variant
    @variant = Dossier::CvVariant.includes(:based_on, user: :dossier_profile).find(params[:id])
  end

  def variant_params
    params.require(:dossier_cv_variant).permit(:name, :target_company, :target_role, :job_description, :voice, :style,
                                               :summary_override, :show_tech_stack, :min_importance)
  end
end
