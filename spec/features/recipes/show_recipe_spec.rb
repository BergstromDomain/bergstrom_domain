# spec/features/recipes/show_recipe_spec.rb

require "rails_helper"

RSpec.describe "Show Recipe", type: :feature do
  let(:charlie) { create(:user, :content_creator, first_name: "Charlie", last_name: "Creator") }
  let(:chris)   { create(:user, :content_creator) }
  let(:cuisine)   { create(:cuisine, name: "Swedish", flag: "🇸🇪") }
  let(:food_type) { create(:food_type, name: "Soup", icon: "soup") }
  let(:language)  { create(:language, name: "English", code: "en", flag: "🇬🇧") }
  let(:recipe) do
    create(:recipe, :published, :unrestricted,
      user: charlie, title: "Pea Soup", description: "A Thursday classic.",
      cuisine: cuisine, food_type: food_type, language: language,
      serves: 4, cook_time: "2 hours", body: "1. Soak the peas overnight.",
      ingredient_sections_attributes: {
        "0" => { heading: "Soup", ingredients_attributes: {
          "0" => { quantity: "5", measurement: "dl", name: "yellow peas", comment: "soaked overnight" },
          "1" => { quantity: "1", name: "onion" }
        } },
        "1" => { heading: "To serve", ingredients_attributes: { "0" => { quantity: "a dollop", name: "mustard" } } }
      })
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit recipe_path(recipe) }

    it "Shows the title, the Language flag and the description" do
      expect(page).to have_selector("h1.page-title", text: "Pea Soup")
      expect(page).to have_selector("[data-testid='recipe-language'] .flag-badge__flag", text: "🇬🇧")
      expect(page).to have_selector("[data-testid='recipe-description']", text: "A Thursday classic.")
    end

    it "Shows the Cuisine flag in place of a missing image" do
      expect(page).to have_selector("[data-testid='recipe-cuisine-image'] .flag-badge__flag", text: "🇸🇪")
    end

    it "Shows the metadata: Food Type, Cuisine, Serves, Cook Time and Chef" do
      within("[data-testid='show-panel-metadata']") do
        expect(page).to have_link("Soup",    href: food_type_path(food_type))
        expect(page).to have_link("Swedish", href: cuisine_path(cuisine))
        expect(page).to have_selector("[data-testid='recipe-portions']", text: "4")
        expect(page).to have_selector("[data-testid='recipe-portions-label']", text: "Serves")
        expect(page).to have_selector("[data-testid='recipe-cook-time']", text: "2 hours")
        expect(page).to have_selector("[data-testid='recipe-chef']", text: "Charlie Creator")
        expect(page).to have_selector("[data-testid='recipe-comments-count']", text: "0")
        expect(page).to have_selector("[data-testid='recipe-likes-count']", text: "No reactions yet")
      end
    end

    it "Lists each ingredient list under its heading, in order, amount then ingredient" do
      sections = all("[data-testid='recipe-ingredient-section']")
      expect(sections.map { |s| s.find("h3").text }).to eq([ "Soup", "To serve" ])
      within(sections.first) do
        rows = all("[data-testid='recipe-ingredient']")
        expect(rows.first).to have_selector(".recipe-ingredient__amount", text: "5 dl")
        expect(rows.first).to have_selector(".recipe-ingredient__name", text: "yellow peas")
        expect(rows.first).to have_selector(".recipe-ingredient__comment", text: "soaked overnight")
        expect(rows.last).to have_selector(".recipe-ingredient__amount", text: "1")
      end
    end

    it "Renders the method from Markdown" do
      within("[data-testid='recipe-method']") do
        expect(page).to have_selector("ol li", text: "Soak the peas overnight.")
      end
    end

    it "Defaults 'Back' to the Cookbook" do
      expect(page).to have_link("Back", href: cookbook_path, exact: true)
    end

    it "Shows no Draft warning on a published recipe" do
      expect(page).not_to have_selector("[data-testid='draft-mode-warning']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Keeps another user's draft from 'Chris Content Creator'" do
      draft = create(:recipe, user: charlie)
      sign_in_as(chris)
      visit recipe_path(draft)
      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_content("You do not have permission to view that recipe.")
    end

    it "Keeps a contacts-only recipe from 'Gary Guest'" do
      contacts_only = create(:recipe, :published, :contacts, user: charlie)
      visit recipe_path(contacts_only)
      expect(page).to have_current_path(cookbook_path)
    end

    it "Returns 404 for a non-existent slug" do
      visit recipe_path("no-such-recipe")
      expect(page).to have_http_status(:not_found)
    end

    it "Ignores a return_to that points off-site" do
      visit recipe_path(recipe, return_to: "https://evil.example.com/")
      expect(page).to have_link("Back", href: cookbook_path, exact: true)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the owner their own draft with the Draft warning" do
      draft = create(:recipe, user: charlie, title: "Work In Progress")
      sign_in_as(charlie)
      visit recipe_path(draft)
      expect(page).to have_selector("h1.page-title", text: "Work In Progress")
      expect(page).to have_selector("[data-testid='draft-mode-warning']")
    end

    it "Shows Makes instead of Serves when Makes is set" do
      buns = create(:recipe, :published, :unrestricted, serves: 4, makes: 24)
      visit recipe_path(buns)
      expect(page).to have_selector("[data-testid='recipe-portions-label']", text: "Makes")
      expect(page).to have_selector("[data-testid='recipe-portions']", text: "24")
    end

    it "Sends 'Back' to a relative return_to path" do
      visit recipe_path(recipe, return_to: "/cuisines?x=1")
      expect(page).to have_link("Back", href: "/cuisines?x=1", exact: true)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Hides the description, portions, cook time and an unheaded list's heading when blank" do
      bare = create(:recipe, :published, :unrestricted, description: nil, serves: nil, makes: nil, cook_time: nil,
        ingredient_sections_attributes: { "0" => { ingredients_attributes: { "0" => { quantity: "3", name: "eggs" } } } })
      visit recipe_path(bare)

      expect(page).not_to have_selector("[data-testid='recipe-description']")
      expect(page).not_to have_selector("[data-testid='recipe-portions']")
      expect(page).not_to have_selector("[data-testid='recipe-cook-time']")
      within("[data-testid='recipe-ingredient-section']") { expect(page).not_to have_selector("h3") }
    end

    it "Says so when a recipe has no ingredients yet" do
      visit recipe_path(create(:recipe, :published, :unrestricted))
      expect(page).to have_selector("[data-testid='recipe-no-ingredients']")
    end

    it "Treats a protocol-relative return_to as off-site" do
      visit recipe_path(recipe, return_to: "//evil.example.com/")
      expect(page).to have_link("Back", href: cookbook_path, exact: true)
    end
  end
end
