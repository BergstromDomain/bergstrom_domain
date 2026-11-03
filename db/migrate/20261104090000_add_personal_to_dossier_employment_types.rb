class AddPersonalToDossierEmploymentTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_employment_types, :personal, :boolean, default: false, null: false
  end
end
