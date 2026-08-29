# spec/features/blog_categories/delete_blog_category_spec.rb

require "rails_helper"

RSpec.describe "Delete blog category", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Deletes a blog category with no associated blog posts and redirects to index" do
      bc = create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      visit blog_category_path(bc)
      click_button "Delete Blog Category"
      expect(page).to have_current_path(blog_categories_path)
      expect(page).not_to have_content("Travel")
    end

    it "Removes the blog category from the database" do
      bc = create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      visit blog_category_path(bc)
      expect {
        click_button "Delete Blog Category"
      }.to change(BlogCategory, :count).by(-1)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Does not delete a blog category that has associated blog posts" do
      bc = create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      create(:blog_post, blog_category: bc)
      visit blog_category_path(bc)
      expect {
        click_button "Delete Blog Category"
      }.not_to change(BlogCategory, :count)
    end

    it "Shows an error when deletion is prevented by associated blog posts" do
      bc = create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      create(:blog_post, blog_category: bc)
      visit blog_category_path(bc)
      click_button "Delete Blog Category"
      expect(page).to have_content("Cannot delete record because dependent blog posts exist")
    end

    it "Does not show the 'Delete' button to 'Charlie Content Creator'" do
      bc = create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit blog_category_path(bc)
      expect(page).not_to have_button("Delete Blog Category")
    end

    it "Does not show the 'Delete' button to 'Gary Guest'" do
      bc = create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      click_button "Sign Out"
      visit blog_category_path(bc)
      expect(page).not_to have_button("Delete Blog Category")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows 'Sam SysAdmin' to delete a blog category" do
      bc = create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit blog_category_path(bc)
      click_button "Delete Blog Category"
      expect(page).to have_current_path(blog_categories_path)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows the 'Delete Blog Category' button to an 'Adam Admin'" do
      bc = create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      visit blog_category_path(bc)
      expect(page).to have_button("Delete Blog Category")
    end
  end
end
