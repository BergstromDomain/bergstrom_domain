# Dossier Block 12b — an Assignment's Vendors (who else built it) and
# Customers (who buys or uses the result), as links to Organisations.
# Private to the owner and Admins; never exported.
class CreateDossierAssignmentPartners < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_assignment_partners do |t|
      t.references :assignment,   null: false, foreign_key: { to_table: :dossier_assignments, on_delete: :cascade }, index: false
      t.references :organisation, null: false, foreign_key: { to_table: :dossier_organisations }
      t.string     :kind,         null: false
      t.text       :scope
      t.timestamps
    end
    add_index :dossier_assignment_partners, %i[assignment_id kind organisation_id], unique: true,
              name: "index_dossier_assignment_partners_uniqueness"
  end
end
