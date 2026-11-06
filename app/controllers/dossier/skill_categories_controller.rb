# app/controllers/dossier/skill_categories_controller.rb
class Dossier::SkillCategoriesController < Dossier::ReferenceDataController
  # The category's Skills A–Z, with the signed-in user's years and last use
  # of each (a version's Skill linked, a parent's years including its versions).
  def show
    super
    @skills = @record.skills.alphabetical.includes(:parent).to_a
    return unless current_user

    calculator = Dossier::ExperienceCalculator.new(current_user)
    @skill_experience = @skills.index_with { |skill| calculator.for_skill(skill) }
  end

  private

  def model_class = Dossier::SkillCategory
  def subtitle    = "Skill Categories group Skills, e.g. Test Tools, Methodology or Protocols."
  def show_panels = "dossier/skill_categories/skills"
end
