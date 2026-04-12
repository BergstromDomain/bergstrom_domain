# db/migrate/YYYYMMDDHHMMSS_remove_image_columns_from_people.rb
class RemoveImageColumnsFromPeople < ActiveRecord::Migration[8.1]
  def change
    remove_column :people, :thumbnail_image, :string
    remove_column :people, :full_image, :string
  end
end
