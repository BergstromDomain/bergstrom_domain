# Where a Skill Category sits among its siblings (top-level ones, or a
# parent's sub-categories), e.g. on an Assignment's Tech Stack. Blank sorts
# last, A–Z.
class AddPositionToDossierSkillCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_skill_categories, :position, :integer
  end
end
