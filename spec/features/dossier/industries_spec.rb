# spec/features/dossier/industries_spec.rb
require "rails_helper"

RSpec.describe "Dossier Industries", type: :feature do
  let(:factory)     { :dossier_industry }
  let(:model)       { Dossier::Industry }
  let(:singular)    { "Industry" }
  let(:plural)      { "Industries" }
  let(:index_path)  { dossier_industries_path }
  let(:new_path)    { new_dossier_industry_path }
  let(:record_name) { "Mining Technology" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    fill_in "Description", with: "Software for mining operations."
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false

  describe "Negative Path (Industry)" do
    it "Won't delete an Industry an Organisation uses, and says why" do
      industry = create(:dossier_industry)
      create(:dossier_organisation, industry: industry)
      sign_in_as(create(:user, :admin))
      visit dossier_industry_path(industry)

      expect { click_button "Delete Industry" }.not_to change(Dossier::Industry, :count)
      expect(page).to have_content("Cannot delete record because dependent organisations exist")
    end
  end
end
