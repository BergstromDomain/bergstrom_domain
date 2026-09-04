# spec/features/blog_categories/show_blog_category_spec.rb

require "rails_helper"

RSpec.describe "Show blog category", type: :feature do
  let(:admin)           { create(:user, :admin) }
  let(:content_creator) { create(:user, :content_creator) }
  let!(:blog_category) do
    create(:blog_category,
      name:        "Technology",
      icon:        "cpu",
      description: "Posts about technology and gadgets.")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { visit blog_category_path(blog_category) }

    it "Displays the blog category name in the page title" do
      expect(page).to have_selector("h1.page-title", text: "Technology")
    end

    it "Renders the icon in the main panel" do
      expect(page).to have_selector("[data-testid='show-panel-main'] svg")
    end

    it "Displays the blog category description" do
      expect(page).to have_selector("[data-testid='blog-category-description']",
                               text: "Posts about technology and gadgets.")
    end

    it "Displays the blog category name in the metadata panel" do
      expect(page).to have_selector("[data-testid='blog-category-name-value']", text: "Technology")
    end

    it "Shows a back link to the index" do
      expect(page).to have_link("Back to Blog Categories", href: blog_categories_path)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Gary Guest'" do
      expect(page).not_to have_link("Edit Blog Category")
      expect(page).not_to have_button("Delete Blog Category")
    end

    it "Is accessible by slug" do
      visit blog_category_path(blog_category.slug)
      expect(page).to have_selector("h1.page-title", text: "Technology")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns 404 for a non-existent slug" do
      visit blog_category_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Charlie Content Creator'" do
      sign_in_as content_creator
      visit blog_category_path(blog_category)
      expect(page).not_to have_link("Edit Blog Category")
      expect(page).not_to have_button("Delete Blog Category")
    end

    it "Does not show the 'Edit' nor the 'Delete' buttons to 'Uno User'" do
      sign_in_as create(:user, :app_user)
      visit blog_category_path(blog_category)
      expect(page).not_to have_link("Edit Blog Category")
      expect(page).not_to have_button("Delete Blog Category")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    context "As 'Adam Admin'" do
      before do
        sign_in_as admin
        visit blog_category_path(blog_category)
      end

      it "Shows the 'Edit' button" do
        expect(page).to have_link("Edit Blog Category",
                                  href: edit_blog_category_path(blog_category))
      end

      it "Shows the 'Delete' button" do
        expect(page).to have_button("Delete Blog Category")
      end

      it "Shows the button divider between the 'Back' and the 'Edit' buttons" do
        expect(page).to have_selector(".btn-divider")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Handles a blog category with a long name without breaking layout" do
      long = create(:blog_category, name: "A" * 60, description: "Test.", icon: "star")
      visit blog_category_path(long)
      expect(page).to have_selector("h1.page-title")
    end

    it "Shows both the 'Edit' and the 'Delete' buttons to 'Sam SysAdmin'" do
      sign_in_as create(:user, :system_admin)
      visit blog_category_path(blog_category)
      expect(page).to have_link("Edit Blog Category")
      expect(page).to have_button("Delete Blog Category")
    end
  end
end
