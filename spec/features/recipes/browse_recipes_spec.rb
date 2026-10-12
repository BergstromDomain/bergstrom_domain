# spec/features/recipes/browse_recipes_spec.rb

require "rails_helper"

RSpec.describe "Browse Recipes", type: :feature do
  let(:chef)     { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }
  let!(:french)  { create(:cuisine, name: "French", flag: "🇫🇷") }
  let!(:italian) { create(:cuisine, name: "Italian", flag: "🇮🇹") }
  let!(:swedish) { create(:cuisine, name: "Swedish", flag: "🇸🇪") }
  let!(:pasta)   { create(:food_type, name: "Pasta", icon: "cooking-pot") }
  let!(:mince)   { create(:food_type, name: "Mince Meat", icon: "beef") }
  let!(:soup)    { create(:food_type, name: "Soup", icon: "soup") }
  let(:english)  { create(:language, name: "English", code: "en", flag: "🇬🇧") }

  let!(:lasagna) do
    create(:recipe, :published, :unrestricted, user: chef, title: "Swedish Lasagna",
      cuisines: [ swedish, italian ], food_types: [ pasta, mince ], language: english,
      serves: 6, cook_time: "1 hour", created_at: 2.days.ago)
  end
  let!(:carbonara) do
    create(:recipe, :published, :unrestricted, user: chef, title: "Carbonara",
      cuisines: [ italian ], food_types: [ pasta ], language: english)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists every Cuisine with its count, a recipe counting under both of its Cuisines" do
      visit browse_by_cuisine_recipes_path

      expect(page).to have_selector("[data-testid='browse-root']", text: "Browse Recipes By Cuisine")
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Cookbook (2)", href: browse_by_cuisine_recipes_path)
        expect(page).to have_link("French (0)")
        expect(page).to have_link("Italian (2)")
        expect(page).to have_link("Swedish (1)")
      end
      expect(page).to have_no_selector("[data-testid='browse-preview']")
    end

    it "Shows a breadcrumb and a card per recipe in a Cuisine, newest first" do
      visit browse_by_cuisine_recipes_path
      click_link "Italian (2)"

      expect(page).to have_selector("[data-testid='browse-breadcrumb-current']", text: "Italian")
      within("[data-testid='browse-preview']") do
        expect(page).to have_selector("[data-testid='browse-preview-heading']", text: "Recipes in Italian (2)")
        expect(all("[data-testid='browse-recipe-title']").map(&:text)).to eq([ "Carbonara", "Swedish Lasagna" ])
      end
    end

    it "Browses by Food Type the same way" do
      visit browse_by_food_type_recipes_path

      expect(page).to have_selector("[data-testid='browse-root']", text: "Browse Recipes By Food Type")
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Mince Meat (1)")
        expect(page).to have_link("Pasta (2)")
        expect(page).to have_link("Soup (0)")
      end

      click_link "Mince Meat (1)"
      expect(page).to have_selector("[data-testid='browse-recipe-card']", count: 1)
    end

    it "Displays the correct fields on each recipe card" do
      lasagna.likes.create!(user: create(:user), face: "neutral")
      create_list(:comment, 2, commentable: lasagna)
      visit browse_by_cuisine_recipes_path(cuisine_id: swedish.slug)

      within("[data-testid='browse-recipe-card']") do
        expect(page).to have_selector("[data-testid='browse-recipe-cuisine-image'] .flag-badge__flag", text: "🇸🇪")
        expect(page).to have_selector("[data-testid='browse-recipe-language'] .flag-badge__flag", text: "🇬🇧")
        expect(page).to have_selector("[data-testid='browse-recipe-meta-left']",
          text: "Filed Under: Swedish · Italian » Pasta · Mince Meat")
        expect(page).to have_selector("[data-testid='browse-recipe-chef']", text: "Ada Lovelace")
        expect(page).to have_selector("[data-testid='browse-recipe-created']", text: lasagna.created_at.strftime("%d-%b-%Y"))
        expect(page).to have_selector("[data-testid='browse-recipe-portions']", text: "Serves: 6")
        expect(page).to have_selector("[data-testid='browse-recipe-cook-time']", text: "1 hour")
        expect(page).to have_selector("[data-testid='browse-recipe-reactions']", text: "3.0")
        expect(page).to have_selector("[data-testid='browse-recipe-comments']", text: "2")
      end
    end

    it "Opens a recipe with Back returning to the Browse page it came from" do
      visit browse_by_cuisine_recipes_path(cuisine_id: swedish.slug)
      click_link "Swedish Lasagna"

      expect(page).to have_current_path(recipe_path(lasagna, return_to: browse_by_cuisine_recipes_path(cuisine_id: swedish.slug)))
      click_link "Back"
      expect(page).to have_current_path(browse_by_cuisine_recipes_path(cuisine_id: swedish.slug))
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Never counts or shows a restricted recipe to 'Gary Guest'" do
      create(:recipe, :published, :restricted, user: chef, title: "Secret Sauce", cuisines: [ french ])
      visit browse_by_cuisine_recipes_path(cuisine_id: french.slug)

      expect(page).to have_selector("[data-testid='browse-preview-heading']", text: "Recipes in French (0)")
      expect(page).not_to have_content("Secret Sauce")
    end

    it "Returns to the Browse root for an unknown Cuisine" do
      visit browse_by_cuisine_recipes_path(cuisine_id: "no-such-cuisine")
      expect(page).to have_current_path(browse_by_cuisine_recipes_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows the owner their own draft" do
      create(:recipe, user: chef, title: "Work In Progress", cuisines: [ french ])
      sign_in_as(chef)
      visit browse_by_cuisine_recipes_path(cuisine_id: french.slug)

      expect(page).to have_selector("[data-testid='browse-recipe-title']", text: "Work In Progress")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an empty message for a Cuisine with no recipes" do
      visit browse_by_cuisine_recipes_path(cuisine_id: french.slug)
      expect(page).to have_selector("[data-testid='empty-state']", text: "No recipes here yet.")
    end

    it "Leaves out Serves/Makes and Cook Time when they are blank" do
      visit browse_by_cuisine_recipes_path(cuisine_id: italian.slug)
      card = all("[data-testid='browse-recipe-card']").find { |c| c.text.include?("Carbonara") }
      expect(card).to have_no_selector("[data-testid='browse-recipe-portions']")
      expect(card).to have_no_selector("[data-testid='browse-recipe-cook-time']")
    end
  end
end
