# Dossier Block 1b — one Profile per user. The terse summary is stored once;
# first- and third-person versions are optional overrides (Q-D6).
class CreateDossierProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_profiles do |t|
      t.references :user,     null: false, foreign_key: true, index: { unique: true }
      t.string     :display_name, null: false
      t.string     :headline
      t.references :location, foreign_key: { to_table: :dossier_locations }
      t.string     :email
      t.string     :phone
      t.string     :website_url
      t.string     :linkedin_url
      t.string     :github_url
      t.text       :summary
      t.text       :summary_first_person
      t.text       :summary_third_person
      t.string     :third_person_name
      t.string     :pronouns,       null: false, default: "they"
      t.string     :classification, null: false, default: "restricted"
      t.timestamps
    end
  end
end
