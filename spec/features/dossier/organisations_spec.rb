# spec/features/dossier/organisations_spec.rb
require "rails_helper"

RSpec.describe "Dossier Organisations", type: :feature do
  let(:factory)     { :dossier_organisation }
  let(:model)       { Dossier::Organisation }
  let(:singular)    { "Organisation" }
  let(:plural)      { "Organisations" }
  let(:index_path)  { dossier_organisations_path }
  let(:new_path)    { new_dossier_organisation_path }
  let(:record_name) { "Northwind Transport Authority" }
  let!(:transport)  { create(:dossier_industry, name: "Transport") }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    fill_in "Abbreviation", with: "NTA"
    select "Transport", from: "Industry"
    fill_in "Website", with: "https://northwind.example"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: true

  describe "Happy Path (Organisation)" do
    it "Shows the abbreviation, industry and website" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      click_button "Create Organisation"

      expect(page).to have_selector("[data-testid='detail-abbreviation']", text: "NTA")
      expect(page).to have_selector("[data-testid='detail-industry']", text: "Transport")
      expect(page).to have_link("https://northwind.example", href: "https://northwind.example")
    end
  end

  describe "Negative Path (Organisation)" do
    it "Rejects a website that isn't an http(s) URL" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      fill_in "Website", with: "northwind.example"
      click_button "Create Organisation"

      expect(page).to have_content("must start with http:// or https://")
    end
  end
end
