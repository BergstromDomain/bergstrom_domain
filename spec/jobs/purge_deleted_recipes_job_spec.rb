# spec/jobs/purge_deleted_recipes_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedRecipesJob, type: :job do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Permanently destroys a recipe deleted more than 30 days ago" do
      recipe = create(:recipe, user: owner, deleted_at: 31.days.ago)
      described_class.perform_now
      expect(Recipe.exists?(recipe.id)).to be false
    end

    it "Destroys its ingredient lists, ingredients and reactions along with it" do
      recipe = create(:recipe, :published, user: owner)
      create(:like, likeable: recipe, user: create(:user))
      recipe.update!(deleted_at: 31.days.ago)

      expect { described_class.perform_now }
        .to change(IngredientSection, :count).by(-1)
        .and change(Ingredient, :count).by(-1)
        .and change(Like, :count).by(-1)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves a recipe deleted less than 30 days ago untouched" do
      recipe = create(:recipe, user: owner, deleted_at: 1.day.ago)
      described_class.perform_now
      expect(Recipe.exists?(recipe.id)).to be true
    end

    it "Leaves a kept (never deleted) recipe untouched regardless of age" do
      recipe = create(:recipe, user: owner, created_at: 1.year.ago)
      described_class.perform_now
      expect(Recipe.exists?(recipe.id)).to be true
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Destroys multiple eligible recipes in one run" do
      create(:recipe, user: owner, deleted_at: 40.days.ago)
      create(:recipe, deleted_at: 35.days.ago)
      described_class.perform_now
      expect(Recipe.discarded.count).to eq(0)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Treats a recipe deleted just under 30 days ago as not yet eligible" do
      recipe = create(:recipe, user: owner, deleted_at: 30.days.ago + 1.minute)
      described_class.perform_now
      expect(Recipe.exists?(recipe.id)).to be true
    end

    it "Does nothing when there are no deleted recipes" do
      create(:recipe, user: owner)
      expect { described_class.perform_now }.not_to change(Recipe, :count)
    end
  end
end
