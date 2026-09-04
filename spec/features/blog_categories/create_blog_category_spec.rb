# spec/features/blog_categories/create_blog_category_spec.rb

require "rails_helper"

RSpec.describe "Create blog category", type: :feature do
  let(:admin) { create(:user, :admin) }

  before { sign_in_as(admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Creates a blog category with all required fields" do
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Posts about technology."
      fill_in "Icon",        with: "cpu"
      click_button "Create Blog Category"

      expect(page).to have_selector("h1.page-title", text: "Technology")
      expect(page).to have_selector("svg")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows an error when name is missing" do
      visit new_blog_category_path
      fill_in "Description", with: "Something."
      fill_in "Icon",        with: "star"
      click_button "Create Blog Category"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(BlogCategory.count).to eq(0)
    end

    it "Shows an error when name is a duplicate (same case)" do
      create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Another tech category."
      fill_in "Icon",        with: "server"
      click_button "Create Blog Category"

      expect(page).to have_content("has already been taken")
      expect(BlogCategory.count).to eq(1)
    end

    it "Shows an error when name is a duplicate (different case)" do
      create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.")
      visit new_blog_category_path
      fill_in "Name",        with: "technology"
      fill_in "Description", with: "Another tech category."
      fill_in "Icon",        with: "server"
      click_button "Create Blog Category"

      expect(page).to have_content("has already been taken")
      expect(BlogCategory.count).to eq(1)
    end

    it "Shows an error when description is missing" do
      visit new_blog_category_path
      fill_in "Name", with: "Technology"
      fill_in "Icon", with: "cpu"
      click_button "Create Blog Category"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(BlogCategory.count).to eq(0)
    end

    it "Shows an error when icon is missing" do
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Posts about technology."
      click_button "Create Blog Category"

      expect(page).to have_selector("[data-testid='field-error']")
      expect(page).to have_content("can't be blank")
      expect(BlogCategory.count).to eq(0)
    end

    it "Shows an error when icon is not a valid Lucide icon name" do
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Posts about technology."
      fill_in "Icon",        with: "not-a-real-icon"
      click_button "Create Blog Category"

      expect(page).to have_content("is not a valid Lucide icon name")
      expect(BlogCategory.count).to eq(0)
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      click_button "Sign Out"
      visit new_blog_category_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects 'Charlie Content Creator' to the blog categories index" do
      click_button "Sign Out"
      sign_in_as create(:user, :content_creator)
      visit new_blog_category_path
      expect(page).to have_current_path(blog_categories_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Re-renders the form with entered values when validation fails" do
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Posts about technology."
      fill_in "Icon",        with: "not-a-real-icon"
      click_button "Create Blog Category"

      expect(page).to have_field("Name", with: "Technology")
      expect(page).to have_field("Icon", with: "not-a-real-icon")
    end

    it "Allows 'Sam SysAdmin' to create a blog category" do
      click_button "Sign Out"
      sign_in_as create(:user, :system_admin)
      visit new_blog_category_path
      fill_in "Name",        with: "Travel"
      fill_in "Description", with: "Travel posts."
      fill_in "Icon",        with: "plane"
      click_button "Create Blog Category"

      expect(page).to have_selector("h1.page-title", text: "Travel")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows an error when icon has surrounding whitespace" do
      visit new_blog_category_path
      fill_in "Name",        with: "Technology"
      fill_in "Description", with: "Posts about technology."
      fill_in "Icon",        with: " cpu "
      click_button "Create Blog Category"

      expect(page).to have_content("is not a valid Lucide icon name")
    end
  end
end
