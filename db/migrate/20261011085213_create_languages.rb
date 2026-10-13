class CreateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :languages do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :flag, null: false
      t.string :slug

      t.timestamps
    end

    add_index :languages, :name, unique: true
    add_index :languages, :code, unique: true
    add_index :languages, :slug, unique: true
  end
end
