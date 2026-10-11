# spec/features/recipes/react_to_recipe_spec.rb

require "rails_helper"

RSpec.describe "React to Recipe", type: :feature do
  let(:reader) { create(:user) }
  let(:recipe) { create(:recipe, :published, :unrestricted) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lets a signed-in user react, and shows the score in the metadata" do
      sign_in_as(reader)
      visit recipe_path(recipe)
      find("[data-testid='like-grinning']").click

      expect(page).to have_current_path(recipe_path(recipe))
      expect(page).to have_selector("[data-testid='like-grinning'].like-button--active")
      expect(page).to have_selector("[data-testid='recipe-likes-count']", text: "5.0")
      expect(recipe.likes.find_by(user: reader).face).to eq("grinning")
    end

    it "Lets the user clear their reaction" do
      sign_in_as(reader)
      visit recipe_path(recipe)
      find("[data-testid='like-grinning']").click
      find("[data-testid='like-clear']").click

      expect(page).not_to have_selector("[data-testid='like-clear']")
      expect(recipe.likes.find_by(user: reader).face).to be_nil
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows 'Gary Guest' no React panel when nobody has reacted" do
      visit recipe_path(recipe)
      expect(page).not_to have_selector("[data-testid='likes-panel']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows 'Gary Guest' the aggregate face, not clickable" do
      recipe.likes.create!(user: reader, face: "grinning")
      visit recipe_path(recipe)
      expect(page).to have_selector("span[data-testid='like-grinning'].like-button--active")
      expect(page).not_to have_button(class: "like-button")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows the reaction breakdown in the metadata popup" do
      recipe.likes.create!(user: reader, face: "angry")
      visit recipe_path(recipe)
      expect(page).to have_selector("[data-testid='likes-breakdown-total']", text: "1 reaction", visible: :all)
    end
  end
end
