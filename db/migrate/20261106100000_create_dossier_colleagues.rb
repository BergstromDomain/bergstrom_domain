# Dossier Block 12a — Colleagues: people you worked with on an Assignment.
# Private to the owner and Admins; never exported.
class CreateDossierColleagues < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_colleagues do |t|
      t.references :assignment,   null: false, foreign_key: { to_table: :dossier_assignments, on_delete: :cascade }
      t.string     :name,         null: false
      t.string     :position
      t.string     :mobile
      t.string     :email
      t.string     :linkedin_url
      t.text       :comment
      t.timestamps
    end
  end
end
