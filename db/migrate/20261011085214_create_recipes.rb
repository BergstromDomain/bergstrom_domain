class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string     :title,          null: false
      t.text       :description
      t.text       :body
      t.string     :format,         null: false, default: "formatted"
      t.integer    :serves
      t.integer    :makes
      t.string     :cook_time
      t.string     :classification, null: false, default: "contacts"
      t.string     :slug
      t.datetime   :published_at
      t.datetime   :deleted_at
      # Comment's polymorphic counter_cache needs this on every commentable host.
      t.integer    :comments_count, null: false, default: 0
      t.references :user,           null: false, foreign_key: true
      t.references :cuisine,        null: false, foreign_key: true
      t.references :food_type,      null: false, foreign_key: true
      t.references :language,       null: false, foreign_key: true

      t.timestamps
    end

    add_index :recipes, :slug, unique: true
    add_index :recipes, :deleted_at
    add_index :recipes, [ :user_id, :title ], unique: true
  end
end
