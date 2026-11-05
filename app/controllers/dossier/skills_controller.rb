# app/controllers/dossier/skills_controller.rb
class Dossier::SkillsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true
  # Its own callback: re-declaring set_record here would replace the parent's.
  before_action :set_skill_to_merge, only: %i[merge perform_merge]

  # The signed-in user's own experience with the Skill, Training included (nil
  # for a visitor or a Skill they haven't used or trained in).
  def show
    super
    return unless current_user

    @experience = Dossier::ExperienceCalculator.new(current_user).for_skill(@record)
    return unless @experience

    ActiveRecord::Associations::Preloader.new(records: @experience.assignments, associations: :client).call
    ActiveRecord::Associations::Preloader.new(records: @experience.training, associations: :provider).call
  end

  # Merging folds this Skill into the one chosen to keep (Admin only).
  def merge
    @targets = merge_targets
  end

  def perform_merge
    target = merge_targets.find_by(id: params[:target_id])
    unless target
      @targets = merge_targets
      @error = "Choose the Skill to keep."
      render :merge, status: :unprocessable_entity and return
    end

    label = @record.to_toast_label
    @record.merge_into!(target)
    toast_merged(label, into: target)
    redirect_to dossier_skill_path(target)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    redirect_to dossier_skill_path(@record), flash: { error: "#{label} couldn't be merged: #{e.message}" }
  end

  private

  def model_class          = Dossier::Skill
  def permitted_attributes = %i[name skill_category_id aliases_text description]
  def subtitle             = "Tools, methods, platforms and protocols. Aliases catch other spellings of the same Skill."
  def show_panels          = "dossier/skills/experience"
  def show_actions         = ("dossier/skills/merge_action" if current_user&.can_administer?)

  def merge_targets = Dossier::Skill.alphabetical.where.not(id: @record.id)

  def set_skill_to_merge
    set_record
    redirect_to dossier_skill_path(@record), alert: "Not authorised." unless current_user&.can_administer?
  end

  # Grouped under their Skill Categories, alphabetically.
  def index_groups
    @records.includes(:skill_category).group_by(&:skill_category)
            .sort_by { |category, _| category.name.downcase }
            .map { |category, skills| [ category.name, skills ] }
  end

  def details(record)
    [ [ "Skill Category", record.skill_category.name, "skill-category" ],
      [ "Aliases",        record.aliases_text.presence, "aliases" ] ]
  end
end
