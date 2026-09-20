class ConvertCommentsToPolymorphic < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :comments, :blog_posts
    remove_index :comments, name: "index_comments_on_blog_post_id"

    rename_column :comments, :blog_post_id, :commentable_id
    add_column :comments, :commentable_type, :string, null: false, default: "BlogPost"
    change_column_default :comments, :commentable_type, from: "BlogPost", to: nil

    add_index :comments, %i[commentable_type commentable_id]
  end

  def down
    remove_index :comments, column: %i[commentable_type commentable_id]

    remove_column :comments, :commentable_type
    rename_column :comments, :commentable_id, :blog_post_id

    add_foreign_key :comments, :blog_posts
    add_index :comments, :blog_post_id
  end
end
