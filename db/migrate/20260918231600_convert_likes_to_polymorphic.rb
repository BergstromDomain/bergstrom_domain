class ConvertLikesToPolymorphic < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :likes, :blog_posts
    remove_index :likes, name: "index_likes_on_blog_post_id_and_user_id"
    remove_index :likes, name: "index_likes_on_blog_post_id"

    rename_column :likes, :blog_post_id, :likeable_id
    add_column :likes, :likeable_type, :string, null: false, default: "BlogPost"
    change_column_default :likes, :likeable_type, from: "BlogPost", to: nil

    add_index :likes, %i[likeable_type likeable_id]
    add_index :likes, %i[user_id likeable_type likeable_id],
      unique: true, name: "index_likes_on_user_and_likeable"

    change_column_null :likes, :face, true
    change_column_default :likes, :face, from: "neutral", to: nil
  end

  def down
    remove_index :likes, name: "index_likes_on_user_and_likeable"
    remove_index :likes, column: %i[likeable_type likeable_id]

    remove_column :likes, :likeable_type
    rename_column :likes, :likeable_id, :blog_post_id

    add_foreign_key :likes, :blog_posts
    add_index :likes, :blog_post_id
    add_index :likes, %i[blog_post_id user_id], unique: true,
      name: "index_likes_on_blog_post_id_and_user_id"

    change_column_default :likes, :face, from: nil, to: "neutral"
    change_column_null :likes, :face, false
  end
end
