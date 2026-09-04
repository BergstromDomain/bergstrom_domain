class RemoveLikesCountFromBlogPosts < ActiveRecord::Migration[8.1]
  def change
    remove_column :blog_posts, :likes_count, :integer, null: false, default: 0
  end
end
