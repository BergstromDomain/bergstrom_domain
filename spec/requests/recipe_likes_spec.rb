# spec/requests/recipe_likes_spec.rb
require "rails_helper"

RSpec.describe "Recipe reactions", type: :request do
  let(:reader) { create(:user) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Records a reaction and returns to the recipe" do
      recipe = create(:recipe, :published, :unrestricted)
      sign_in_as(reader)
      post recipe_like_path(recipe), params: { face: "grinning" }
      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.likes.find_by(user: reader).face).to eq("grinning")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Refuses a reaction on someone else's draft" do
      draft = create(:recipe)
      sign_in_as(reader)
      post recipe_like_path(draft), params: { face: "grinning" }
      expect(response).to redirect_to(cookbook_path)
      expect(draft.likes).to be_empty
    end

    it "Refuses clearing a reaction on someone else's draft" do
      draft = create(:recipe)
      sign_in_as(reader)
      delete recipe_like_path(draft)
      expect(response).to redirect_to(cookbook_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Rejects an unknown face" do
      recipe = create(:recipe, :published, :unrestricted)
      sign_in_as(reader)
      post recipe_like_path(recipe), params: { face: "meh" }
      expect(response).to redirect_to(recipe_path(recipe))
      expect(recipe.likes).to be_empty
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Returns 404 for an unknown recipe" do
      sign_in_as(reader)
      post recipe_like_path("no-such-recipe"), params: { face: "grinning" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
