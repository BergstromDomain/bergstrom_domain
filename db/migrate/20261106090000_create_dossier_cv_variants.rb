# Dossier Block 8 — CV Variants: a tailored CV picked from the master data.
# An item row ticks or unticks one Engagement, Assignment, Achievement, Skill
# or Credential; with no row, the variant's default rules decide.
class CreateDossierCvVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_cv_variants do |t|
      t.references :user,             null: false, foreign_key: true
      t.string     :name,             null: false
      t.string     :target_company
      t.string     :target_role
      t.text       :job_description
      t.string     :voice,            null: false, default: "first_person"
      t.string     :style,            null: false, default: "classic"
      t.text       :summary_override
      t.boolean    :show_tech_stack,  null: false, default: false
      t.integer    :min_importance,   null: false, default: 3
      t.references :based_on,         foreign_key: { to_table: :dossier_cv_variants, on_delete: :nullify }
      t.string     :classification,   null: false, default: "restricted"
      t.timestamps
    end
    add_index :dossier_cv_variants, "user_id, LOWER(name)", unique: true, name: "index_dossier_cv_variants_on_user_and_lower_name"

    create_table :dossier_cv_variant_items do |t|
      t.references :cv_variant, null: false, foreign_key: { to_table: :dossier_cv_variants, on_delete: :cascade }, index: false
      t.references :item,       null: false, polymorphic: true
      t.boolean    :included,   null: false
      t.timestamps
    end
    add_index :dossier_cv_variant_items, %i[cv_variant_id item_type item_id], unique: true,
              name: "index_dossier_cv_variant_items_uniqueness"
  end
end
