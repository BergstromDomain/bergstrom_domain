# spec/features/blog_categories/list_blog_category_spec.rb

require "rails_helper"

RSpec.describe "List blog categories", type: :feature do
  let!(:technology) { create(:blog_category, name: "Technology", icon: "cpu",   description: "Tech posts.") }
  let!(:cooking)     { create(:blog_category, name: "Cooking",    icon: "chef-hat", description: "Cooking posts.") }
  let!(:travel)      { create(:blog_category, name: "Travel",     icon: "plane", description: "Travel posts.") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { visit blog_categories_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Blog Categories")
    end

    it "Displays all blog categories" do
      expect(page).to have_content("Technology")
      expect(page).to have_content("Cooking")
      expect(page).to have_content("Travel")
    end

    it "Displays blog categories in alphabetical order by name" do
      expect(page.text.index("Cooking")).to be < page.text.index("Technology")
      expect(page.text.index("Technology")).to be < page.text.index("Travel")
    end

    it "Renders an SVG icon for each blog category" do
      expect(page).to have_selector("td[data-testid='blog-category-icon'] svg", minimum: 3)
    end

    it "Displays the description for each blog category" do
      expect(page).to have_selector("td[data-testid='blog-category-description']", count: 3)
    end

    it "Links each blog category name to its show page" do
      expect(page).to have_link("Technology", href: blog_category_path(technology))
      expect(page).to have_link("Cooking",    href: blog_category_path(cooking))
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Displays an empty state message when no blog categories exist" do
      BlogCategory.delete_all
      visit blog_categories_path
      expect(page).to have_http_status(:ok)
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Renders the same page regardless of authentication status" do
      sign_in_as create(:user, :app_user)
      visit blog_categories_path
      expect(page).to have_selector("h1.page-title", text: "Blog Categories")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Sorts blog categories case-insensitively" do
      create(:blog_category, name: "acoustic vinyl reviews", icon: "disc", description: "Music reviews.")
      visit blog_categories_path
      expect(page.text.index("acoustic vinyl reviews")).to be < page.text.index("Cooking")
    end
  end
end
