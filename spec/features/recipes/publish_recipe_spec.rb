# spec/features/recipes/publish_recipe_spec.rb

require "rails_helper"

RSpec.describe "Publish Recipe", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  # A draft with one ingredient row, ready to publish when it has a Method.
  def complete_draft(**attrs)
    create(:recipe, user: charlie, **attrs).tap do |recipe|
      recipe.ingredient_sections.create!(position: 0).ingredients.create!(quantity: "1", name: "onion", position: 0)
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(charlie) }

    it "Publishes a complete draft and flips the button to Unpublish" do
      recipe = complete_draft(title: "Pea Soup")
      visit recipe_path(recipe)

      click_button "Publish"

      expect(page).to have_current_path(recipe_path(recipe))
      expect(page).to have_css("[data-testid='flash-success']", text: "Pea Soup has been successfully published")
      expect(page).to have_no_css("[data-testid='draft-mode-warning']")
      expect(page).to have_button("Unpublish")
      expect(recipe.reload).to be_published
    end

    it "Unpublishes a published recipe and flips the button back to Publish" do
      recipe = create(:recipe, :published, user: charlie, title: "Pea Soup")
      visit recipe_path(recipe)

      click_button "Unpublish"

      expect(page).to have_css("[data-testid='flash-success']", text: "Pea Soup has been successfully unpublished")
      expect(page).to have_css("[data-testid='draft-mode-warning']")
      expect(page).to have_button("Publish")
      expect(recipe.reload).not_to be_published
    end

    it "Shows Back | Edit | Publish in the action frame" do
      visit recipe_path(complete_draft)
      within("[data-testid='show-panel-actions']") do
        expect(page).to have_link("Back")
        expect(page).to have_link("Edit")
        expect(page).to have_css("[data-testid='publish-button']")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Refuses to publish without a Method" do
      recipe = complete_draft(body: nil)
      sign_in_as(charlie)
      visit recipe_path(recipe)

      click_button "Publish"

      expect(page).to have_css("[data-testid='flash-error']", text: "Cannot publish: Method can't be blank")
      expect(recipe.reload).not_to be_published
    end

    it "Refuses to publish without an ingredient" do
      recipe = create(:recipe, user: charlie)
      sign_in_as(charlie)
      visit recipe_path(recipe)

      click_button "Publish"

      expect(page).to have_css("[data-testid='flash-error']", text: "Cannot publish: Add at least one ingredient before publishing")
      expect(recipe.reload).not_to be_published
    end

    it "Does not show Edit or Publish/Unpublish to another content creator" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      sign_in_as(create(:user, :content_creator))
      visit recipe_path(recipe)

      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Publish")
      expect(page).to have_no_button("Unpublish")
    end

    it "Does not show Edit or Publish/Unpublish to 'Gary Guest'" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      visit recipe_path(recipe)

      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Unpublish")
    end

    it "Denies a direct unpublish request from another content creator" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      sign_in_as(create(:user, :content_creator))

      page.driver.submit :post, unpublish_recipe_path(recipe), {}

      expect(page).to have_content("Not authorised")
      expect(recipe.reload).to be_published
    end

    it "Denies the owner when their Cookbook update permission is revoked" do
      recipe = complete_draft
      create(:app_permission, user: charlie, app_name: "recipes", can_update: false)
      sign_in_as(charlie)
      visit recipe_path(recipe)
      expect(page).to have_no_button("Publish")

      page.driver.submit :post, publish_recipe_path(recipe), {}
      expect(recipe.reload).not_to be_published
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Adam Admin' to publish anyone's recipe" do
      recipe = complete_draft
      sign_in_as(create(:user, :admin))
      visit recipe_path(recipe)

      click_button "Publish"

      expect(recipe.reload).to be_published
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Can be re-published after being unpublished" do
      recipe = create(:recipe, :published, user: charlie)
      sign_in_as(charlie)
      visit recipe_path(recipe)

      click_button "Unpublish"
      expect(recipe.reload).not_to be_published

      click_button "Publish"
      expect(recipe.reload).to be_published
    end
  end
end
