class CreateBlogCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_categories do |t|
      t.string :name,        null: false
      t.text   :description, null: false
      t.string :icon,        null: false
      t.string :slug

      t.timestamps
    end

    add_index :blog_categories, :name, unique: true
    add_index :blog_categories, :icon, unique: true
    add_index :blog_categories, :slug, unique: true
  end
end
