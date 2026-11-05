# spec/features/dossier/credential_types_spec.rb
require "rails_helper"

RSpec.describe "Dossier Credential Types", type: :feature do
  let(:factory)     { :dossier_credential_type }
  let(:model)       { Dossier::CredentialType }
  let(:singular)    { "Credential Type" }
  let(:plural)      { "Credential Types" }
  let(:index_path)  { dossier_credential_types_path }
  let(:new_path)    { new_dossier_credential_type_path }
  let(:record_name) { "Certification" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    fill_in "Sort Order", with: "3"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false

  describe "Happy Path (Credential Type)" do
    it "Saves and shows the Sort Order and Training flag" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_name("Workshop")
      fill_in "Sort Order", with: "5"
      check "Training"
      click_button "Create Credential Type"

      expect(Dossier::CredentialType.find_by!(name: "Workshop")).to have_attributes(position: 5, training: true)
      expect(page).to have_selector("[data-testid='detail-position']", text: "5")
      expect(page).to have_selector("[data-testid='detail-training']", text: "Yes")
    end
  end

  describe "Alternative Path (Credential Type)" do
    it "Lists types in their sort order rather than alphabetically" do
      create(:dossier_credential_type, name: "Course", position: 4)
      create(:dossier_credential_type, name: "Degree", position: 1)
      visit index_path

      expect(all("[data-testid='reference-data-name']").map(&:text)).to eq(%w[Degree Course])
    end
  end
end
