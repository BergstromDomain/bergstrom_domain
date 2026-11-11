# app/controllers/dossier/skill_categories_controller.rb
class Dossier::SkillCategoriesController < Dossier::ReferenceDataController
  # The category's Skills A–Z, its sub-categories' included, with the
  # signed-in user's years and last use of each (a version's Skill linked, a
  # parent's years including its versions).
  def show
    super
    @subcategories = @record.subcategories.to_a
    @skills = @record.all_skills.alphabetical.includes(:parent)
    # Each Skill's sub-category is shown only when there are sub-categories.
    @skills = @skills.includes(:skill_category) if @subcategories.any?
    @skills = @skills.to_a
    return unless current_user

    calculator = Dossier::ExperienceCalculator.new(current_user)
    @skill_experience = @skills.index_with { |skill| calculator.for_skill(skill) }
  end

  private

  def model_class          = Dossier::SkillCategory
  def permitted_attributes = %i[name description parent_id soft]
  def subtitle             = "Skill Categories group Skills, e.g. Test Tools, Methodology or Protocols. " \
                             "A category can have sub-categories, one level deep."
  def show_panels          = "dossier/skill_categories/skills"

  # Each top-level category followed by its sub-categories.
  def index_groups = [ [ nil, @records.in_tree_order ] ]

  def details(record)
    part_of = record.parent && helpers.link_to(record.parent.name, dossier_skill_category_path(record.parent))
    [ [ "Part Of", part_of, "part-of" ],
      [ "Professional Skills", record.soft_skills? ? "Yes" : "No", "soft" ] ]
  end
end
