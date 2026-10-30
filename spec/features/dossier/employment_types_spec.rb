# spec/features/dossier/employment_types_spec.rb
require "rails_helper"

RSpec.describe "Dossier Employment Types", type: :feature do
  let(:factory)     { :dossier_employment_type }
  let(:model)       { Dossier::EmploymentType }
  let(:singular)    { "Employment Type" }
  let(:plural)      { "Employment Types" }
  let(:index_path)  { dossier_employment_types_path }
  let(:new_path)    { new_dossier_employment_type_path }
  let(:record_name) { "Permanent Employment" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    check "Permanent"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false

  describe "Happy Path (Employment Type)" do
    it "Saves and shows the Permanent flag" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      click_button "Create Employment Type"

      expect(Dossier::EmploymentType.find_by!(name: record_name).permanent).to be(true)
      expect(page).to have_selector("[data-testid='detail-permanent']", text: "Yes")
    end
  end
end
