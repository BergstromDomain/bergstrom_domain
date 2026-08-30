class RenameSubCategoryToSubjectOnBlogPosts < ActiveRecord::Migration[8.1]
  def change
    rename_column :blog_posts, :sub_category, :subject
  end
end
