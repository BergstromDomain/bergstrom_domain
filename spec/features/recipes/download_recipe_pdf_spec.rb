# spec/features/recipes/download_recipe_pdf_spec.rb

require "rails_helper"

RSpec.describe "Download Recipe PDF", type: :feature do
  let(:chef) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows a Download PDF link on the Read page" do
      recipe = create(:recipe, :published, :unrestricted, user: chef)
      visit recipe_path(recipe)

      expect(page).to have_selector("[data-testid='download-pdf-link']", text: "Download PDF")
    end

    it "Downloads a PDF named after the recipe title" do
      recipe = create(:recipe, :published, :unrestricted, user: chef, title: "Swedish Lasagna")
      visit recipe_path(recipe)
      click_link "Download PDF"

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
      expect(page.response_headers["Content-Disposition"]).to include("Swedish_Lasagna.pdf")
      expect(page.body.byteslice(0, 5)).to eq("%PDF-")
    end

    it "Lays the PDF out as a printed recipe, without comments or reactions" do
      recipe = create(:recipe, :published, :unrestricted, user: chef, title: "Swedish Lasagna",
        cuisines: [ create(:cuisine, name: "Swedish"), create(:cuisine, name: "Italian") ],
        food_types: [ create(:food_type, name: "Pasta") ], serves: 6, cook_time: "1 hour",
        description: "A family favourite", body: "Layer the sauce and pasta.",
        ingredient_sections_attributes: { "0" => { heading: "Sauce", ingredients_attributes: {
          "0" => { quantity: "1", measurement: "tbsp", name: "Butter", comment: "softened" } } } })
      create(:comment, commentable: recipe, body: "Lovely comment")

      html = RecipesController.render(template: "recipes/pdf", layout: false, assigns: { recipe: recipe })
      text = Capybara.string(html)

      expect(text).to have_selector("h1", text: "Swedish Lasagna")
      expect(text).to have_selector(".pdf-meta", text: "Swedish · Italian » Pasta")
      expect(text).to have_selector(".pdf-meta", text: "Serves: 6")
      expect(text).to have_selector(".pdf-meta", text: "Cook Time: 1 hour")
      expect(text).to have_content("A family favourite")
      expect(text).to have_selector("h2", text: "Ingredients")
      expect(text).to have_selector("h3", text: "Sauce")
      expect(text).to have_selector("li", text: "1 tbsp Butter, softened")
      expect(text).to have_selector("h2", text: "Method")
      expect(text).to have_content("Layer the sauce and pasta.")
      expect(text).not_to have_content("Lovely comment")
      expect(text).not_to have_content("reaction")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' away from a restricted recipe's PDF" do
      recipe = create(:recipe, :published, :restricted, user: chef)
      visit pdf_recipe_path(recipe)

      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Returns 404 for a non-existent recipe" do
      visit pdf_recipe_path("no-such-recipe")
      expect(page).to have_http_status(:not_found)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets the chef download their own draft's PDF" do
      recipe = create(:recipe, user: chef)
      sign_in_as(chef)
      visit pdf_recipe_path(recipe)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Renders a recipe with an uploaded image" do
      recipe = create(:recipe, :published, :unrestricted, user: chef)
      recipe.recipe_image.attach(io: file_fixture("test_image.jpg").open, filename: "test_image.jpg", content_type: "image/jpeg")
      visit pdf_recipe_path(recipe)

      expect(page.body.byteslice(0, 5)).to eq("%PDF-")
    end
  end
end
