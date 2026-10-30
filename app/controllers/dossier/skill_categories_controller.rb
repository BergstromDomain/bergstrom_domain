# app/controllers/dossier/skill_categories_controller.rb
class Dossier::SkillCategoriesController < Dossier::ReferenceDataController
  private

  def model_class = Dossier::SkillCategory
  def subtitle    = "Skill Categories group Skills, e.g. Test Tools, Methodology or Protocols."
end
