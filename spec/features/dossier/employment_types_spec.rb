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

    it "Saves and shows the Personal flag" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_name("Personal Project")
      check "Personal"
      click_button "Create Employment Type"

      expect(Dossier::EmploymentType.find_by!(name: "Personal Project").personal).to be(true)
      expect(page).to have_selector("[data-testid='detail-personal']", text: "Yes")
    end

    it "Saves and shows the Career Break flag" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_name("Career Break")
      check "Career Break"
      click_button "Create Employment Type"

      expect(page).to have_css("[data-testid='flash-success']", text: "has been successfully created")
      expect(Dossier::EmploymentType.find_by!(name: "Career Break").career_break).to be(true)
      expect(page).to have_selector("[data-testid='detail-career-break']", text: "Yes")
    end
  end

  describe "Alternative Path (Employment Type)" do
    it "Lets Sam tick Career Break on an existing type from Edit" do
      type = create(:dossier_employment_type, name: "Time Off")
      sign_in_as(create(:user, :system_admin))
      visit edit_dossier_employment_type_path(type)
      check "Career Break"
      click_button "Update Employment Type"

      expect(page).to have_selector("[data-testid='detail-career-break']", text: "Yes")
      expect(type.reload.career_break).to be(true)
    end
  end

  describe "Negative Path (Employment Type)" do
    it "Shows the error for a type ticked both Career Break and Permanent" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_name("Odd Type")
      check "Permanent"
      check "Career Break"
      click_button "Create Employment Type"

      expect(page).to have_text("can't be both a career break and permanent")
    end
  end
end
