# db/migrate/YYYYMMDDHHMMSS_remove_image_columns_from_events.rb
class RemoveImageColumnsFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :image, :string
    remove_column :events, :thumbnail_image, :string
  end
end
