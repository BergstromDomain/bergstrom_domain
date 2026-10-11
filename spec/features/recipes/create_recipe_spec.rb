# spec/features/recipes/create_recipe_spec.rb

require "rails_helper"

RSpec.describe "Create Recipe", type: :feature do
  let(:charlie)    { create(:user, :content_creator) }
  let!(:swedish_c) { create(:cuisine, name: "Swedish", flag: "🇸🇪") }
  let!(:soup)      { create(:food_type, name: "Soup", icon: "soup") }
  let!(:english)   { create(:language, name: "English", code: "en", flag: "🇬🇧") }
  let!(:svenska)   { create(:language, name: "Swedish", code: "sv", flag: "🇸🇪") }

  # Like the Blog Post editor specs: under Selenium, native <select> popups
  # and WebDriver keystrokes have both proved unreliable on CI, so JS
  # examples set values directly. rack_test examples use the real helpers.
  def js? = Capybara.current_driver == Capybara.javascript_driver

  def set_value(field, value)
    return field.set(value) unless js?

    page.execute_script(<<~JS, field, value)
      const [input, value] = arguments
      input.value = value
      input.dispatchEvent(new Event("input", { bubbles: true }))
    JS
  end

  def choose(label, from:)
    field = find_field(from)
    return field.select(label) unless js?

    page.execute_script(<<~JS, field, label)
      const [select, label] = arguments
      select.value = [ ...select.options ].find((option) => option.text === label).value
      select.dispatchEvent(new Event("change", { bubbles: true }))
    JS
  end

  def fill_required(title: "Pea Soup")
    set_value(find_field("Title"), title)
    choose("Swedish", from: "Cuisine")
    choose("Soup",    from: "Food Type")
  end

  def fill_row(row, quantity:, name:, measurement: nil, comment: nil)
    within(row) do
      set_value(find("[data-testid='ingredient-quantity-field']"), quantity)
      set_value(find("[data-testid='ingredient-measurement-field']"), measurement) if measurement
      set_value(find("[data-testid='ingredient-name-field']"), name)
      set_value(find("[data-testid='ingredient-comment-field']"), comment) if comment
    end
  end

  def save
    js? ? js_click("save-button") : click_button("Save Recipe")
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(charlie) }

    it "Creates a draft recipe and returns to the Cookbook with a toast" do
      visit new_recipe_path
      fill_required
      fill_in "Description", with: "A Thursday classic."
      fill_in "Serves",      with: "4"
      fill_in "Cook Time",   with: "2 hours"
      click_button "Save Recipe"

      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "Pea Soup has been successfully created")

      recipe = Recipe.find_by!(title: "Pea Soup")
      expect(recipe).to have_attributes(
        user: charlie, cuisine: swedish_c, food_type: soup, language: english,
        description: "A Thursday classic.", serves: 4, cook_time: "2 hours", published_at: nil
      )
    end

    it "Starts with one unheaded ingredient list holding one blank row" do
      visit new_recipe_path
      expect(page).to have_css("[data-testid='ingredient-section']", count: 1)
      expect(page).to have_css("[data-testid='ingredient-row']", count: 1)
      expect(find("[data-testid='section-heading-field']").value).to be_blank
    end

    it "Saves the ingredient row" do
      visit new_recipe_path
      fill_required
      fill_row(find("[data-testid='ingredient-row']"), quantity: "5", measurement: "dl", name: "yellow peas", comment: "soaked overnight")
      click_button "Save Recipe"

      ingredient = Recipe.find_by!(title: "Pea Soup").ingredient_sections.first.ingredients.first
      expect(ingredient).to have_attributes(quantity: "5", measurement: "dl", name: "yellow peas", comment: "soaked overnight")
    end

    it "Links 'Write A Recipe' from the left nav" do
      visit cookbook_path
      within("[data-testid='left-nav']") { click_link "Write A Recipe" }
      expect(page).to have_current_path(new_recipe_path)
    end

    context "With JavaScript", js: true do
      it "Adds rows and a second headed list, and saves them in order" do
        visit new_recipe_path
        fill_required(title: "Lasagna")

        first_section = find("[data-testid='ingredient-section']")
        set_value(first_section.find("[data-testid='section-heading-field']"), "Meat sauce")
        fill_row(first_section.find("[data-testid='ingredient-row']"), quantity: "500", measurement: "g", name: "minced beef")
        within(first_section) { js_click("add-ingredient-button") }
        expect(first_section).to have_css("[data-testid='ingredient-row']", count: 2)
        fill_row(first_section.all("[data-testid='ingredient-row']").last, quantity: "1", name: "onion")

        js_click("add-section-button")
        expect(page).to have_css("[data-testid='ingredient-section']", count: 2)
        second_section = all("[data-testid='ingredient-section']").last
        set_value(second_section.find("[data-testid='section-heading-field']"), "White sauce")
        fill_row(second_section.find("[data-testid='ingredient-row']"), quantity: "5", measurement: "dl", name: "milk")

        save
        expect(page).to have_current_path(cookbook_path, wait: 10)

        sections = Recipe.find_by!(title: "Lasagna").ingredient_sections
        expect(sections.map(&:heading)).to eq([ "Meat sauce", "White sauce" ])
        expect(sections.first.ingredients.map(&:name)).to eq([ "minced beef", "onion" ])
        expect(sections.last.ingredients.map(&:name)).to eq([ "milk" ])
      end

      it "Removes an added row and an added list before saving" do
        visit new_recipe_path
        fill_required
        fill_row(find("[data-testid='ingredient-row']"), quantity: "5", measurement: "dl", name: "yellow peas")
        js_click("add-ingredient-button")
        all("[data-testid='ingredient-row']").last.find("[data-testid='remove-ingredient-button']").execute_script("this.click()")
        expect(page).to have_css("[data-testid='ingredient-row']", count: 1)

        js_click("add-section-button")
        all("[data-testid='ingredient-section']").last.find("[data-testid='remove-section-button']").execute_script("this.click()")
        expect(page).to have_css("[data-testid='ingredient-section']", count: 1)

        save
        expect(page).to have_current_path(cookbook_path, wait: 10)
        recipe = Recipe.find_by!(title: "Pea Soup")
        expect(recipe.ingredient_sections.count).to eq(1)
        expect(recipe.ingredient_sections.first.ingredients.map(&:name)).to eq([ "yellow peas" ])
      end

      it "Saves the Raw body as Markdown" do
        visit new_recipe_path
        fill_required
        js_click("raw-tab")
        set_value(find("[data-testid='body-field']"), "1. Soak the peas")
        save

        expect(page).to have_current_path(cookbook_path, wait: 10)
        expect(Recipe.find_by!(title: "Pea Soup").body).to include("Soak the peas")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit new_recipe_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Redirects 'Uno User' (app_user role) to the Cookbook" do
      sign_in_as(create(:user, :app_user))
      visit new_recipe_path
      expect(page).to have_current_path(cookbook_path)
    end

    it "Redirects a content creator whose Cookbook create permission is revoked" do
      create(:app_permission, user: charlie, app_name: "recipes", can_create: false)
      sign_in_as(charlie)
      visit new_recipe_path
      expect(page).to have_current_path(cookbook_path)
    end

    context "As 'Charlie Content Creator'" do
      before { sign_in_as(charlie) }

      it "Shows errors when Title, Cuisine and Food Type are missing" do
        visit new_recipe_path
        click_button "Save Recipe"

        expect(page).to have_content("Title can't be blank")
        expect(page).to have_content("Cuisine can't be blank")
        expect(page).to have_content("Food type can't be blank")
        expect(Recipe.count).to eq(0)
      end

      it "Shows an error on a row with an ingredient but no quantity, keeping what was typed" do
        visit new_recipe_path
        fill_required
        fill_row(find("[data-testid='ingredient-row']"), quantity: "", name: "salt")
        click_button "Save Recipe"

        expect(page).to have_content("Quantity can't be blank")
        expect(find("[data-testid='ingredient-name-field']").value).to eq("salt")
        expect(page).to have_css("[data-testid='ingredient-quantity-field'].form-control--error")
        expect(Recipe.count).to eq(0)
      end

      it "Shows an error when the title is already used by the same user" do
        create(:recipe, user: charlie, title: "Pea Soup")
        visit new_recipe_path
        fill_required
        click_button "Save Recipe"
        expect(page).to have_content("has already been taken")
      end

      it "Shows an error when Language is cleared and no default exists" do
        english.destroy!
        visit new_recipe_path
        fill_required
        click_button "Save Recipe"
        expect(page).to have_content("Language can't be blank")
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    before { sign_in_as(charlie) }

    it "Pre-selects the Language and Classification from Cookbook Settings" do
      charlie.app_settings_for("recipes").update!(default_language: svenska, default_classification: "unrestricted")
      visit new_recipe_path
      expect(page).to have_select("Language", selected: "Swedish")
      expect(page).to have_select("Classification", selected: "Unrestricted — visible to everyone")
    end

    it "Pre-selects English and Restricted when nothing is set" do
      visit new_recipe_path
      expect(page).to have_select("Language", selected: "English")
      expect(page).to have_select("Classification", selected: "Restricted — visible only to me")
    end

    it "Keeps both Serves and Makes when both are filled in" do
      visit new_recipe_path
      fill_required(title: "Buns")
      fill_in "Serves", with: "4"
      fill_in "Makes",  with: "24"
      click_button "Save Recipe"

      expect(Recipe.find_by!(title: "Buns")).to have_attributes(serves: 4, makes: 24)
    end

    it "Allows 'Adam Admin' to write a recipe" do
      click_button "Sign Out"
      sign_in_as(create(:user, :admin))
      visit new_recipe_path
      fill_required
      click_button "Save Recipe"
      expect(page).to have_current_path(cookbook_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    before { sign_in_as(charlie) }

    it "Keeps a free-text quantity exactly as typed" do
      visit new_recipe_path
      fill_required
      fill_row(find("[data-testid='ingredient-row']"), quantity: "2–3", name: "garlic cloves")
      click_button "Save Recipe"

      expect(Ingredient.last.quantity).to eq("2–3")
    end

    it "Ignores the starting row when it is left blank" do
      visit new_recipe_path
      fill_required
      click_button "Save Recipe"

      expect(Recipe.find_by!(title: "Pea Soup").ingredient_sections).to be_empty
    end

    it "Rejects Serves of zero" do
      visit new_recipe_path
      fill_required
      fill_in "Serves", with: "0"
      click_button "Save Recipe"
      expect(page).to have_content("Serves must be greater than 0")
    end
  end
end
