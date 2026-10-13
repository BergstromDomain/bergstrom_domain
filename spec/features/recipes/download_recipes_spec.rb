# spec/features/recipes/download_recipes_spec.rb

require "rails_helper"

RSpec.describe "Download Recipes", type: :feature do
  let(:chef)     { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }
  let!(:italian) { create(:cuisine, name: "Italian") }
  let!(:swedish) { create(:cuisine, name: "Swedish") }

  let!(:carbonara) { create(:recipe, :published, :unrestricted, user: chef, title: "Carbonara", cuisines: [ italian ]) }
  let!(:pea_soup)  { create(:recipe, :published, :unrestricted, user: chef, title: "Pea Soup", cuisines: [ swedish ]) }

  def zip_entry_names(body)
    names = []
    Zip::InputStream.open(StringIO.new(body)) do |io|
      while (entry = io.get_next_entry)
        names << entry.name
      end
    end
    names
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(chef) }

    it "Shows the filter, the download actions and a results table" do
      visit recipe_exports_path

      expect(page).to have_selector("h1", text: "Download Recipes")
      expect(page).to have_selector("[data-testid='basic-panel']")
      expect(page).to have_link("Download PDFs")
      expect(page).to have_link("Download CSV")
      expect(all("[data-testid='filter-recipe-title']").map(&:text)).to contain_exactly("Carbonara", "Pea Soup")
    end

    it "Downloads a CSV of the visible recipes" do
      visit recipe_exports_path
      click_link "Download CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Cookbook_\d{4}-\d{2}-\d{2}\.csv/)
      expect(CSV.parse(page.body, headers: true).map { |row| row["Title"] }).to contain_exactly("Carbonara", "Pea Soup")
    end

    it "Downloads a ZIP with one PDF per visible recipe" do
      visit recipe_exports_path
      click_link "Download PDFs"

      expect(page.response_headers["Content-Type"]).to include("application/zip")
      expect(page.response_headers["Content-Disposition"]).to match(/BergstromDomain_Cookbook_\d{4}-\d{2}-\d{2}\.zip/)
      expect(zip_entry_names(page.body)).to contain_exactly("Carbonara.pdf", "Pea_Soup.pdf")
    end

    it "Downloads only the recipes matching the applied filter" do
      visit recipe_exports_path
      select "Swedish", from: "cuisine_id"
      click_button "Apply Filters"

      expect(all("[data-testid='filter-recipe-title']").map(&:text)).to eq([ "Pea Soup" ])
      click_link "Download CSV"
      expect(CSV.parse(page.body, headers: true).map { |row| row["Title"] }).to eq([ "Pea Soup" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit recipe_exports_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies 'Uno User' (app_user role), including the download links directly" do
      sign_in_as(create(:user))

      [ recipe_exports_path, csv_recipe_exports_path, pdfs_recipe_exports_path ].each do |path|
        visit path
        expect(page).to have_current_path(cookbook_path)
        expect(page).to have_content("Not authorised")
      end
    end

    it "Never downloads another chef's restricted recipe" do
      create(:recipe, :published, :restricted, title: "Secret Sauce")
      sign_in_as(chef)
      visit csv_recipe_exports_path

      expect(page.body).not_to include("Secret Sauce")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Downloads with an SQL ingredients query" do
      create(:recipe, :published, :unrestricted, user: chef, title: "Garlic Bread",
        ingredient_sections_attributes: { "0" => { ingredients_attributes: { "0" => { quantity: "2", name: "Garlic" } } } })
      sign_in_as(chef)
      visit csv_recipe_exports_path(mode: "sql", query: 'ingredients CONTAINS "garlic"')

      expect(CSV.parse(page.body, headers: true).map { |row| row["Title"] }).to eq([ "Garlic Bread" ])
    end

    it "Lets 'Adam Admin' download drafts and restricted recipes" do
      create(:recipe, :restricted, title: "Restricted Draft")
      sign_in_as(create(:user, :admin))
      visit csv_recipe_exports_path

      expect(page.body).to include("Restricted Draft")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Numbers PDFs whose recipes share a title" do
      create(:recipe, :published, :unrestricted, title: "Carbonara")
      sign_in_as(chef)
      visit pdfs_recipe_exports_path

      expect(zip_entry_names(page.body)).to contain_exactly("Carbonara.pdf", "Carbonara_2.pdf", "Pea_Soup.pdf")
    end

    it "Asks before downloading, naming how many recipes" do
      sign_in_as(chef)
      visit recipe_exports_path

      expect(page).to have_selector("[data-testid='download-pdfs-link'][data-turbo-confirm='Download these 2 recipes?']")
    end
  end
end
