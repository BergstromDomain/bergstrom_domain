# Dossier Block 3 — Achievements: the CV bullet points, each under one
# Assignment, in the user's order, tagged with Skills. Soft-deleted, so a
# bullet is never lost by accident.
class CreateDossierAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_achievements do |t|
      t.references :assignment,     null: false, foreign_key: { to_table: :dossier_assignments }
      t.references :user,           null: false, foreign_key: true
      t.text       :text,           null: false
      t.string     :impact
      t.integer    :importance,     null: false, default: 3
      t.integer    :position,       null: false
      t.string     :classification, null: false, default: "restricted"
      t.datetime   :deleted_at
      t.timestamps
    end
    add_index :dossier_achievements, %i[assignment_id position]

    create_table :dossier_achievement_skills do |t|
      t.references :achievement, null: false, foreign_key: { to_table: :dossier_achievements }
      t.references :skill,       null: false, foreign_key: { to_table: :dossier_skills }
      t.timestamps
    end
    add_index :dossier_achievement_skills, %i[achievement_id skill_id], unique: true
  end
end
