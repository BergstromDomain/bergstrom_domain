class CreateFoodTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :food_types do |t|
      t.string :name,        null: false
      t.text   :description, null: false
      t.string :icon,        null: false
      t.string :slug

      t.timestamps
    end

    add_index :food_types, :name, unique: true
    add_index :food_types, :icon, unique: true
    add_index :food_types, :slug, unique: true
  end
end
