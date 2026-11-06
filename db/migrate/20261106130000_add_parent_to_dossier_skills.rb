# Skill versions: a Skill can be a version of another (Windows XP of
# Windows), one level deep, so a CV can show "Windows (XP, Vista)".
class AddParentToDossierSkills < ActiveRecord::Migration[8.1]
  def change
    add_reference :dossier_skills, :parent, foreign_key: { to_table: :dossier_skills, on_delete: :nullify }
  end
end
