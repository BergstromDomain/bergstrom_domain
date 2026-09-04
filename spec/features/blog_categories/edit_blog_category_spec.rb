# spec/features/blog_categories/edit_blog_category_spec.rb

require "rails_helper"

RSpec.describe "Edit blog category", type: :feature do
  let(:admin)           { create(:user, :admin) }
  let!(:blog_category)  { create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.") }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Updates the name and regenerates the slug" do
      bc = create(:blog_category, name: "Fitness", icon: "dumbbell", description: "Fitness posts.")
      visit edit_blog_category_path(bc)
      fill_in "Name", with: "Sport"
      click_button "Update Blog Category"
      bc.reload
      expect(page).to have_current_path(blog_category_path(bc))
      expect(page).to have_selector("h1.page-title", text: "Sport")
      expect(bc.slug).to eq("sport")
    end

    it "Updates the icon and shows the new icon on the show page" do
      bc = create(:blog_category, name: "Sport", icon: "dumbbell", description: "Sport posts.")
      visit edit_blog_category_path(bc)
      fill_in "Icon", with: "trophy"
      click_button "Update Blog Category"
      expect(page).to have_selector("[data-testid='blog-category-icon'] svg")
      bc.reload
      expect(bc.icon).to eq("trophy")
    end

    it "Shows the edit form heading with the blog category name" do
      visit edit_blog_category_path(blog_category)
      expect(page).to have_selector("h1.page-title", text: "Technology")
    end

    it "Pre-populates the name field" do
      visit edit_blog_category_path(blog_category)
      expect(page).to have_field("Name", with: "Technology")
    end

    it "Pre-populates the icon field" do
      visit edit_blog_category_path(blog_category)
      expect(page).to have_field("Icon", with: "cpu")
    end

    it "Shows a preview of the current icon on the edit form" do
      visit edit_blog_category_path(blog_category)
      expect(page).to have_selector("[data-testid='edit-panel-main'] svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an error when updated name is already taken" do
      create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      bc = create(:blog_category, name: "Sport", icon: "trophy", description: "Sport posts.")
      visit edit_blog_category_path(bc)
      fill_in "Name", with: "Travel"
      click_button "Update Blog Category"
      expect(page).to have_content("has already been taken")
      bc.reload
      expect(bc.name).to eq("Sport")
    end

    it "Shows an error when icon is not a valid Lucide icon name" do
      bc = create(:blog_category, name: "Sport", icon: "trophy", description: "Sport posts.")
      visit edit_blog_category_path(bc)
      fill_in "Icon", with: "not-a-real-icon"
      click_button "Update Blog Category"
      expect(page).to have_content("is not a valid Lucide icon name")
      bc.reload
      expect(bc.icon).to eq("trophy")
    end

    it "Redirects 'Charlie Content Creator' to the blog categories index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit edit_blog_category_path(blog_category)
      expect(page).to have_current_path(blog_categories_path)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit edit_blog_category_path(blog_category)
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Old slug resolves to the record after a name change" do
      bc = create(:blog_category, name: "Fitness", icon: "dumbbell", description: "Fitness posts.")
      old_slug = bc.slug
      visit edit_blog_category_path(bc)
      fill_in "Name", with: "Sport"
      click_button "Update Blog Category"
      visit blog_category_path(old_slug)
      expect(page).to have_selector("h1.page-title", text: "Sport")
    end

    it "Re-renders the form with entered values when validation fails" do
      bc = create(:blog_category, name: "Sport", icon: "trophy", description: "Sport posts.")
      visit edit_blog_category_path(bc)
      fill_in "Name", with: ""
      click_button "Update Blog Category"
      expect(page).to have_field("Icon", with: "trophy")
    end

    it "Allows 'Sam SysAdmin' to edit a blog category" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit edit_blog_category_path(blog_category)
      fill_in "Name", with: "Tech News"
      click_button "Update Blog Category"
      expect(page).to have_selector("h1.page-title", text: "Tech News")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows an error when icon has surrounding whitespace" do
      visit edit_blog_category_path(blog_category)
      fill_in "Icon", with: " cpu "
      click_button "Update Blog Category"
      expect(page).to have_content("is not a valid Lucide icon name")
    end

    it "Preserves the description when only the name is changed" do
      visit edit_blog_category_path(blog_category)
      fill_in "Name", with: "Tech News"
      click_button "Update Blog Category"
      expect(page).to have_selector("[data-testid='blog-category-description']",
                               text: "Tech posts.")
    end
  end
end
