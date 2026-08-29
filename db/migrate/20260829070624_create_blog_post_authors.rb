class CreateBlogPostAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_post_authors do |t|
      t.bigint :blog_post_id, null: false
      t.bigint :user_id,      null: false

      t.timestamps
    end

    add_index :blog_post_authors, [ :blog_post_id, :user_id ], unique: true
    add_foreign_key :blog_post_authors, :blog_posts
    add_foreign_key :blog_post_authors, :users
  end
end
