# app/controllers/dossier/skills_controller.rb
class Dossier::SkillsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true
  # Its own callback: re-declaring set_record here would replace the parent's.
  before_action :set_skill_to_merge, only: %i[merge perform_merge]

  # The signed-in user's own experience with the Skill, Training included (nil
  # for a visitor or a Skill they haven't used or trained in), and their own
  # kept Contributions tagged with it, newest first.
  def show
    super
    @contributions = []
    return unless current_user

    @contributions = current_user.dossier_contributions.kept.newest_first.includes(:event)
                                 .where(id: Dossier::ContributionSkill.where(skill: @record).select(:contribution_id)).to_a
    @experience = Dossier::ExperienceCalculator.new(current_user).for_skill(@record)
    return unless @experience

    ActiveRecord::Associations::Preloader.new(records: @experience.assignments, associations: :client).call
    ActiveRecord::Associations::Preloader.new(records: @experience.training, associations: :provider).call
    return unless @record.soft?

    # A soft Skill shows its example Achievements with their Assignments.
    ActiveRecord::Associations::Preloader.new(records: @experience.achievements, associations: { assignment: %i[client role] }).call
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
  def permitted_attributes = %i[name skill_category_id aliases_text description parent_id vendor_id show_vendor_in_name]
  def subtitle             = "Tools, methods, platforms and protocols. Aliases catch other spellings of the same Skill."
  def show_panels          = "dossier/skills/experience"
  def show_actions         = ("dossier/skills/merge_action" if current_user&.can_administer?)

  def merge_targets = Dossier::Skill.alphabetical.where.not(id: @record.id)

  def set_skill_to_merge
    set_record
    redirect_to dossier_skill_path(@record), alert: "Not authorised." unless current_user&.can_administer?
  end

  # Grouped under their Skill Categories, each top-level one followed by its
  # sub-categories ("Protocols & Standards › VoIP").
  def index_groups
    @records.includes(skill_category: :parent).group_by(&:skill_category)
            .sort_by { |category, _| category.tree_sort_key }
            .map { |category, skills| [ category.full_name, skills ] }
  end

  def details(record)
    category = helpers.link_to(record.skill_category.full_name, dossier_skill_category_path(record.skill_category))
    vendor = record.vendor && helpers.link_to(record.vendor.name, dossier_organisation_path(record.vendor))
    [ [ "Skill Category", category, "skill-category" ],
      [ "Vendor",         vendor, "vendor" ],
      [ "Aliases",        record.aliases_text.presence, "aliases" ],
      [ "Version Of",     (helpers.link_to(record.parent.name, dossier_skill_path(record.parent)) if record.parent), "version-of" ],
      [ "Versions",       helpers.safe_join(record.versions.map { |v| helpers.link_to(v.name, dossier_skill_path(v)) }, ", ").presence,
        "versions" ] ]
  end
end
