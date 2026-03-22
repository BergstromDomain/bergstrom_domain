class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name
      t.text   :description
      t.string :thumbnail_image
      t.string :full_image

      t.timestamps
    end

    add_index :people, [ :first_name, :middle_name, :last_name ],
              name: "index_people_on_full_name"
  end
end
