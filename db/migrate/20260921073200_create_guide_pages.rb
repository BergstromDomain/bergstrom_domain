class CreateGuidePages < ActiveRecord::Migration[8.1]
  def change
    create_table :guide_pages do |t|
      t.string :title,       null: false
      t.string :app_section, null: false
      t.text   :body,        null: false
      t.string :slug

      t.timestamps
    end

    add_index :guide_pages, :title,       unique: true
    add_index :guide_pages, :app_section, unique: true
    add_index :guide_pages, :slug,        unique: true
  end
end
