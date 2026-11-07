# db/migrate/20261106140000_add_position_to_guide_pages.rb

# A page's place in its section's reading order — taken from the number at
# the start of its Markdown file name (02_gary_signs_up.md → 2), so the
# User Guide's story reads chapter by chapter rather than alphabetically.
class AddPositionToGuidePages < ActiveRecord::Migration[8.1]
  def change
    add_column :guide_pages, :position, :integer
  end
end
