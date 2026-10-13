# spec/features/recipes/deleted_recipes_spec.rb

require "rails_helper"

RSpec.describe "Deleted Recipes", type: :feature do
  let(:charlie) { create(:user, :content_creator, first_name: "Charlie", last_name: "Content Creator") }
  let(:admin)   { create(:user, :admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(admin) }

    it "Lists a deleted recipe with its chef and days remaining" do
      recipe = create(:recipe, user: charlie, title: "Gone Soup", deleted_at: 5.days.ago)
      visit deleted_recipes_path

      within("[data-testid='deleted-recipe-row']") do
        expect(page).to have_link("Gone Soup", href: recipe_path(recipe))
        expect(page).to have_css("[data-testid='deleted-recipe-chef']", text: "Charlie Content Creator")
        expect(page).to have_css("[data-testid='deleted-recipe-days-remaining']", text: "25")
      end
    end

    it "Restores a recipe exactly as it was, published included" do
      recipe = create(:recipe, :published, user: charlie, title: "Back Soup", deleted_at: 5.days.ago)
      visit deleted_recipes_path
      find("[data-testid='restore-recipe-#{recipe.id}']").click

      expect(page).to have_current_path(deleted_recipes_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Back Soup has been successfully restored")
      expect(page).to have_no_css("[data-testid='deleted-recipe-row']")
      expect(recipe.reload).to have_attributes(deleted_at: nil, published_at: be_present)
    end

    it "Lets an admin open a deleted recipe from the list" do
      recipe = create(:recipe, user: charlie, title: "Gone Soup", deleted_at: 5.days.ago)
      visit deleted_recipes_path
      click_link "Gone Soup"
      expect(page).to have_current_path(recipe_path(recipe))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Denies a content creator the listing" do
      sign_in_as(charlie)
      visit deleted_recipes_path
      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_content("Not authorised")
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit deleted_recipes_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies a direct restore request from the owner" do
      recipe = create(:recipe, user: charlie, deleted_at: 5.days.ago)
      sign_in_as(charlie)
      page.driver.submit :post, restore_recipe_path(recipe), {}

      expect(page).to have_content("Not authorised")
      expect(recipe.reload.deleted_at).to be_present
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Sam SysAdmin' to restore" do
      recipe = create(:recipe, user: charlie, deleted_at: 5.days.ago)
      sign_in_as(create(:user, :system_admin))
      visit deleted_recipes_path
      find("[data-testid='restore-recipe-#{recipe.id}']").click
      expect(recipe.reload.deleted_at).to be_nil
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    before { sign_in_as(admin) }

    it "Shows an empty state when nothing is deleted" do
      create(:recipe)
      visit deleted_recipes_path
      expect(page).to have_css("[data-testid='empty-state']", text: "No deleted recipes.")
      expect(page).to have_no_css(".data-table")
    end

    it "Lists the most recently deleted first" do
      create(:recipe, title: "Older", deleted_at: 10.days.ago)
      create(:recipe, title: "Newer", deleted_at: 1.day.ago)
      visit deleted_recipes_path
      expect(all("[data-testid='deleted-recipe-title']").map(&:text)).to eq(%w[Newer Older])
    end
  end
end
