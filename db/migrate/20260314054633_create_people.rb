class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :firstname
      t.string :middlename
      t.string :lastname
      t.text :description
      t.string :thumbnail_image
      t.string :full_image

      t.timestamps
    end
  end
end
