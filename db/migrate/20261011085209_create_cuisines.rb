class CreateCuisines < ActiveRecord::Migration[8.1]
  def change
    create_table :cuisines do |t|
      t.string :name,        null: false
      t.text   :description, null: false
      t.string :flag,        null: false
      t.string :slug

      t.timestamps
    end

    add_index :cuisines, :name, unique: true
    add_index :cuisines, :slug, unique: true
  end
end
