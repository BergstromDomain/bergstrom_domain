# spec/features/recipes/delete_recipe_spec.rb

require "rails_helper"

RSpec.describe "Delete Recipe", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(charlie) }

    it "Deletes a recipe and returns to the Cookbook with toasts" do
      recipe = create(:recipe, user: charlie, title: "Pea Soup")
      visit recipe_path(recipe)
      click_button "Delete"

      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Pea Soup has been successfully deleted")
      expect(page).to have_css("[data-testid='flash-info']", text: "The recipe can be restored by Admin for 30 days.")
      expect(recipe.reload.deleted_at).to be_present
    end

    it "Deletes a published recipe directly, without unpublishing it first" do
      recipe = create(:recipe, :published, user: charlie)
      visit recipe_path(recipe)
      click_button "Delete"

      expect(recipe.reload).to have_attributes(deleted_at: be_present, published_at: be_present)
    end

    it "Is no longer visible to the owner once deleted" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      visit recipe_path(recipe)
      click_button "Delete"

      visit recipe_path(recipe)
      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Asks for confirmation, naming the recipe" do
      visit recipe_path(create(:recipe, user: charlie, title: "Pea Soup"))
      expect(find("[data-testid='delete-button']")["data-turbo-confirm"])
        .to eq("Delete \"Pea Soup\"? This can be restored by an admin within 30 days.")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not show Delete to another content creator" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      sign_in_as(create(:user, :content_creator))
      visit recipe_path(recipe)
      expect(page).to have_no_button("Delete")
    end

    it "Denies a direct delete request from another content creator" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      sign_in_as(create(:user, :content_creator))

      page.driver.submit :delete, recipe_path(recipe), {}

      expect(page).to have_content("Not authorised")
      expect(recipe.reload.deleted_at).to be_nil
    end

    it "Denies the owner when their Cookbook delete permission is revoked" do
      recipe = create(:recipe, user: charlie)
      create(:app_permission, user: charlie, app_name: "recipes", can_update: true, can_delete: false)
      sign_in_as(charlie)
      visit recipe_path(recipe)
      expect(page).to have_no_button("Delete")

      page.driver.submit :delete, recipe_path(recipe), {}
      expect(recipe.reload.deleted_at).to be_nil
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      recipe = create(:recipe, :published, :unrestricted, user: charlie)
      page.driver.submit :delete, recipe_path(recipe), {}
      expect(page).to have_current_path(new_session_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Allows 'Adam Admin' to delete anyone's recipe" do
      recipe = create(:recipe, user: charlie)
      sign_in_as(create(:user, :admin))
      visit recipe_path(recipe)
      click_button "Delete"

      expect(recipe.reload.deleted_at).to be_present
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps the ingredients and slug of a deleted recipe" do
      recipe = create(:recipe, :published, user: charlie)
      sign_in_as(charlie)
      visit recipe_path(recipe)
      click_button "Delete"

      recipe.reload
      expect(recipe.ingredient_sections.first.ingredients.count).to eq(1)
      expect(recipe.slug).to be_present
    end
  end
end
