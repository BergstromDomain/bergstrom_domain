# Dossier Block 12g — Staff: people at an Assignment's Vendor or Customer.
# Private to the owner and Admins; never exported.
class CreateDossierStaffMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_staff_members do |t|
      t.references :assignment_partner, null: false,
                                        foreign_key: { to_table: :dossier_assignment_partners, on_delete: :cascade }
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
