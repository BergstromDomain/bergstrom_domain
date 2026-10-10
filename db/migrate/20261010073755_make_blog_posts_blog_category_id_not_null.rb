class MakeBlogPostsBlogCategoryIdNotNull < ActiveRecord::Migration[8.1]
  # Every Blog Post must have a Category, drafts included (see
  # docs/context-prompts/active/Update_Feature_-_Browse_Blog_Posts.md). Safe
  # without a backfill: nothing is deployed to PROD yet, and dev has no
  # category-less posts.
  def change
    change_column_null :blog_posts, :blog_category_id, false
  end
end
