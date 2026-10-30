# Dossier Block 1a — reference data. Names are unique case-insensitively
# (LOWER indexes); slugs back friendly_id.
class CreateDossierReferenceData < ActiveRecord::Migration[8.1]
  def change
    %i[dossier_industries dossier_roles dossier_skill_categories].each do |table|
      create_table table do |t|
        t.string :name, null: false
        t.text   :description
        t.string :slug
        t.timestamps
      end
      add_index table, "LOWER(name)", unique: true, name: "index_#{table}_on_lower_name"
      add_index table, :slug, unique: true
    end

    create_table :dossier_employment_types do |t|
      t.string  :name,      null: false
      t.text    :description
      t.boolean :permanent, null: false, default: false
      t.string  :slug
      t.timestamps
    end
    add_index :dossier_employment_types, "LOWER(name)", unique: true, name: "index_dossier_employment_types_on_lower_name"
    add_index :dossier_employment_types, :slug, unique: true

    create_table :dossier_locations do |t|
      t.string :city,    null: false
      t.string :country, null: false
      t.text   :description
      t.string :slug
      t.timestamps
    end
    add_index :dossier_locations, "LOWER(country), LOWER(city)", unique: true, name: "index_dossier_locations_on_lower_country_and_city"
    add_index :dossier_locations, :slug, unique: true

    create_table :dossier_organisations do |t|
      t.string     :name,         null: false
      t.string     :abbreviation
      t.references :industry,     foreign_key: { to_table: :dossier_industries }
      t.string     :website_url
      t.text       :description
      t.string     :slug
      t.timestamps
    end
    add_index :dossier_organisations, "LOWER(name)", unique: true, name: "index_dossier_organisations_on_lower_name"
    add_index :dossier_organisations, :slug, unique: true

    create_table :dossier_skills do |t|
      t.string     :name,           null: false
      t.references :skill_category, null: false, foreign_key: { to_table: :dossier_skill_categories }
      t.string     :aliases,        array: true, null: false, default: []
      t.text       :description
      t.string     :slug
      t.timestamps
    end
    add_index :dossier_skills, "LOWER(name)", unique: true, name: "index_dossier_skills_on_lower_name"
    add_index :dossier_skills, :slug, unique: true
  end
end
