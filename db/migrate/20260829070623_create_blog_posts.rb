class CreateBlogPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_posts do |t|
      t.string   :title,           null: false
      t.text     :body
      t.string   :format,          null: false, default: "formatted"
      t.string   :sub_category
      t.string   :topic
      t.string   :slug
      t.datetime :published_at
      t.datetime :deleted_at
      t.integer  :comments_count,  null: false, default: 0
      t.integer  :likes_count,     null: false, default: 0
      t.bigint   :user_id,         null: false
      t.bigint   :blog_category_id
      t.string   :classification,  null: false, default: "contacts"

      t.timestamps
    end

    add_index :blog_posts, [ :user_id, :title ], unique: true
    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :blog_category_id
    add_index :blog_posts, :deleted_at

    add_foreign_key :blog_posts, :users
    add_foreign_key :blog_posts, :blog_categories
  end
end
