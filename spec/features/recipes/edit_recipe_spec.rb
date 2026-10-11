# spec/features/recipes/edit_recipe_spec.rb

require "rails_helper"

RSpec.describe "Edit Recipe", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let!(:recipe) do
    create(:recipe, user: charlie, title: "Pea Soup", serves: 4).tap do |r|
      section = r.ingredient_sections.create!(heading: "Soup", position: 0)
      section.ingredients.create!(quantity: "5", measurement: "dl", name: "yellow peas", position: 0)
      section.ingredients.create!(quantity: "1", name: "onion", position: 1)
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(charlie) }

    it "Updates the title and returns to the Read page with toasts" do
      visit edit_recipe_path(recipe)
      fill_in "Title", with: "Yellow Pea Soup"
      click_button "Update Recipe"

      recipe.reload
      expect(page).to have_current_path(recipe_path(recipe))
      expect(page).to have_css("[data-testid='flash-success']", text: "Yellow Pea Soup has been successfully updated")
      expect(page).to have_css("[data-testid='flash-info']", text: "Pea Soup has been updated to Yellow Pea Soup")
      expect(recipe.title).to eq("Yellow Pea Soup")
    end

    it "Pre-populates the form, including the ingredient lists" do
      visit edit_recipe_path(recipe)

      expect(page).to have_css("h1.page-title", text: "Edit Recipe")
      expect(page).to have_field("Title", with: "Pea Soup")
      expect(page).to have_field("Serves", with: "4")
      expect(find("[data-testid='section-heading-field']").value).to eq("Soup")
      expect(all("[data-testid='ingredient-name-field']").map(&:value)).to eq([ "yellow peas", "onion" ])
    end

    it "Edits an existing ingredient row in place" do
      visit edit_recipe_path(recipe)
      all("[data-testid='ingredient-quantity-field']").first.set("6")
      click_button "Update Recipe"

      expect(recipe.reload.ingredient_sections.first.ingredients.first).to have_attributes(quantity: "6", name: "yellow peas")
      expect(Ingredient.count).to eq(2)
    end

    it "Links Edit from the Read page" do
      visit recipe_path(recipe)
      within("[data-testid='show-panel-actions']") { click_link "Edit" }
      expect(page).to have_current_path(edit_recipe_path(recipe))
    end

    context "With JavaScript", js: true do
      before { expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 10) }

      it "Deletes a saved row and a saved list on Update" do
        recipe.ingredient_sections.create!(heading: "Topping", position: 1)
          .ingredients.create!(quantity: "1", name: "mustard", position: 0)
        visit edit_recipe_path(recipe)
        expect(page).to have_css("[data-testid='ingredient-section']", count: 2)

        first_section, second_section = all("[data-testid='ingredient-section']").to_a
        first_section.all("[data-testid='remove-ingredient-button']").last.execute_script("this.click()")
        second_section.find("[data-testid='remove-section-button']").execute_script("this.click()")
        expect(page).to have_css("[data-testid='ingredient-section']", count: 1)

        js_click("save-button")
        expect(page).to have_css("[data-testid='flash-success']", wait: 10)

        sections = recipe.reload.ingredient_sections
        expect(sections.map(&:heading)).to eq([ "Soup" ])
        expect(sections.first.ingredients.map(&:name)).to eq([ "yellow peas" ])
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit edit_recipe_path(recipe)
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies another content creator a published recipe they can read" do
      published = create(:recipe, :published, :unrestricted, user: charlie)
      sign_in_as(create(:user, :content_creator))
      visit edit_recipe_path(published)
      expect(page).to have_current_path(recipe_path(published))
      expect(page).to have_content("Not authorised")
      expect(page).to have_no_button("Update Recipe")
    end

    it "Sends another content creator away from a draft they cannot read" do
      sign_in_as(create(:user, :content_creator))
      visit edit_recipe_path(recipe)
      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_no_button("Update Recipe")
    end

    it "Denies a direct update request from another content creator" do
      sign_in_as(create(:user, :content_creator))
      page.driver.submit :patch, recipe_path(recipe), { recipe: { title: "Hijacked" } }
      expect(recipe.reload.title).to eq("Pea Soup")
    end

    it "Shows errors and keeps what was typed when the title is cleared" do
      sign_in_as(charlie)
      visit edit_recipe_path(recipe)
      fill_in "Title", with: ""
      click_button "Update Recipe"

      expect(page).to have_content("Title can't be blank")
      expect(all("[data-testid='ingredient-name-field']").map(&:value)).to include("yellow peas")
      expect(recipe.reload.title).to eq("Pea Soup")
    end

    it "Refuses to save a published recipe whose last ingredient is removed" do
      published = create(:recipe, :published, user: charlie, title: "Toast")
      sign_in_as(charlie)
      visit edit_recipe_path(published)
      # What the row's Remove button does under JavaScript.
      within(find("[data-testid='ingredient-row']")) do
        find("[data-recipe-ingredients-target='destroy']", visible: false).set("1")
      end
      click_button "Update Recipe"

      expect(page).to have_content("Add at least one ingredient before publishing")
      expect(published.reload.ingredient_sections.first.ingredients.count).to eq(1)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Leaves a published recipe published after an edit" do
      published = create(:recipe, :published, user: charlie, title: "Toast")
      published_at = published.published_at
      sign_in_as(charlie)
      visit edit_recipe_path(published)
      fill_in "Cook Time", with: "5 min"
      click_button "Update Recipe"

      expect(published.reload.published_at).to be_within(1.second).of(published_at)
      expect(page).to have_button("Unpublish")
    end

    it "Allows 'Adam Admin' to edit anyone's recipe" do
      sign_in_as(create(:user, :admin))
      visit edit_recipe_path(recipe)
      fill_in "Cook Time", with: "2 hours"
      click_button "Update Recipe"
      expect(recipe.reload.cook_time).to eq("2 hours")
    end

    it "Cancels back to the Read page" do
      sign_in_as(charlie)
      visit edit_recipe_path(recipe)
      click_link "Cancel"
      expect(page).to have_current_path(recipe_path(recipe))
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    before { sign_in_as(charlie) }

    it "Leaves a draft as a draft after editing" do
      visit edit_recipe_path(recipe)
      fill_in "Cook Time", with: "2 hours"
      click_button "Update Recipe"
      expect(recipe.reload).not_to be_published
    end

    it "Adds a blank starting list when a recipe has no ingredients yet" do
      bare = create(:recipe, user: charlie)
      visit edit_recipe_path(bare)
      expect(page).to have_css("[data-testid='ingredient-row']", count: 1)
    end

    it "Keeps a removed row removed when the update fails" do
      visit edit_recipe_path(recipe)
      fill_in "Title", with: ""
      all("[data-testid='ingredient-row']").last.find("[data-recipe-ingredients-target='destroy']", visible: false).set("1")
      click_button "Update Recipe"

      expect(page).to have_content("Title can't be blank")
      expect(page).to have_css("[data-testid='ingredient-row']", count: 1)
      removed = all("[data-testid='ingredient-row']", visible: :hidden).sole
      expect(removed.find("[data-recipe-ingredients-target='destroy']", visible: false).value).to eq("1")
    end

    it "Follows the old slug to the renamed recipe" do
      visit edit_recipe_path(recipe)
      fill_in "Title", with: "Yellow Pea Soup"
      click_button "Update Recipe"

      visit recipe_path("pea-soup")
      expect(page).to have_css("[data-testid='recipe-title']", text: "Yellow Pea Soup")
    end
  end
end
