# db/migrate/20261111150000_add_professional_skills_to_dossier.rb

# Professional (soft) Skills: a Skill Category can be soft, keeping its
# Skills out of years of experience and the CV's skills table; and an
# Achievement can record the situation it came from (never on a CV).
class AddProfessionalSkillsToDossier < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_skill_categories, :soft, :boolean, null: false, default: false
    add_column :dossier_achievements, :situation, :text
  end
end
