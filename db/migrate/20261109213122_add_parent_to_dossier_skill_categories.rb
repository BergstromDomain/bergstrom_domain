# Sub-categories: a Skill Category can sit under a top-level one (VoIP under
# Protocols & Standards), one level deep. Names are unique within their
# parent, so "Other" can exist under several parents.
class AddParentToDossierSkillCategories < ActiveRecord::Migration[8.1]
  def change
    add_reference :dossier_skill_categories, :parent, foreign_key: { to_table: :dossier_skill_categories }

    remove_index :dossier_skill_categories, "lower((name)::text)", unique: true,
                                                                   name: "index_dossier_skill_categories_on_lower_name"
    add_index :dossier_skill_categories, "COALESCE(parent_id, 0), lower((name)::text)", unique: true,
                                                                                         name: "index_dossier_skill_categories_on_parent_and_lower_name"
  end
end
