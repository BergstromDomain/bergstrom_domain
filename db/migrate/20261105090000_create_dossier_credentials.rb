# Dossier Block 4.5 — Training: Block 5's Credential, started slim with the
# course type only. A course can sit under an Engagement (and one of its
# Assignments) or stand alone, and is tagged with Skills.
class CreateDossierCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_credentials do |t|
      t.references :user,            null: false, foreign_key: true
      t.string     :credential_type, null: false, default: "course"
      t.string     :title,           null: false
      t.references :provider,        foreign_key: { to_table: :dossier_organisations }
      t.references :engagement,      foreign_key: { to_table: :dossier_engagements }
      t.references :assignment,      foreign_key: { to_table: :dossier_assignments }
      t.date       :start_on,        null: false
      t.string     :start_precision, null: false, default: "month"
      t.date       :end_on
      t.string     :end_precision,   null: false, default: "month"
      t.decimal    :hours,           precision: 6, scale: 1
      t.text       :description
      t.string     :classification,  null: false, default: "restricted"
      t.timestamps
    end

    create_table :dossier_credential_skills do |t|
      t.references :credential, null: false, foreign_key: { to_table: :dossier_credentials }
      t.references :skill,      null: false, foreign_key: { to_table: :dossier_skills }
      t.timestamps
    end
    add_index :dossier_credential_skills, %i[credential_id skill_id], unique: true
  end
end
