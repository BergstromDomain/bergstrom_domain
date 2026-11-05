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

    it "Lists your own Training the Organisation provided, not anyone else's" do
      charlie = create(:user, :content_creator)
      ni = create(:dossier_organisation, name: "National Instruments")
      create(:dossier_credential, user: charlie, provider: ni, title: "LabVIEW Core 1", skills_text: "LabVIEW")
      create(:dossier_credential, provider: ni, title: "Someone Else's Course")
      sign_in_as(charlie)
      visit dossier_organisation_path(ni)

      within("[data-testid='organisation-training']") do
        expect(page).to have_link("LabVIEW Core 1")
        expect(page).not_to have_content("Someone Else's Course")
      end
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

    it "Shows a visitor no Training panel" do
      ni = create(:dossier_organisation, name: "National Instruments")
      create(:dossier_credential, provider: ni, title: "LabVIEW Core 1")
      visit dossier_organisation_path(ni)

      expect(page).to have_selector("[data-testid='reference-data-name']", text: "National Instruments")
      expect(page).not_to have_selector("[data-testid='organisation-training']")
    end
  end
end
