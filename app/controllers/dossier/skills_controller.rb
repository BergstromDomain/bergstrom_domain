# app/controllers/dossier/skills_controller.rb
class Dossier::SkillsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true

  private

  def model_class          = Dossier::Skill
  def permitted_attributes = %i[name skill_category_id aliases_text description]
  def subtitle             = "Tools, methods, platforms and protocols. Aliases catch other spellings of the same Skill."

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
