# A Skill's vendor (Microsoft for Project), an optional Dossier Organisation,
# and whether its name is shown with the vendor's: "Microsoft Project".
class AddVendorToDossierSkills < ActiveRecord::Migration[8.1]
  def change
    add_reference :dossier_skills, :vendor, foreign_key: { to_table: :dossier_organisations }
    add_column :dossier_skills, :show_vendor_in_name, :boolean, null: false, default: false
  end
end
