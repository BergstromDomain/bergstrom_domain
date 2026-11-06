# spec/features/dossier/skills_spec.rb
require "rails_helper"

RSpec.describe "Dossier Skills", type: :feature do
  let(:factory)     { :dossier_skill }
  let(:model)       { Dossier::Skill }
  let(:singular)    { "Skill" }
  let(:plural)      { "Skills" }
  let(:index_path)  { dossier_skills_path }
  let(:new_path)    { new_dossier_skill_path }
  let(:record_name) { "Selenium" }
  let!(:test_tools) { create(:dossier_skill_category, name: "Test Tools") }

  def sortable_attributes(text) = { name: text, skill_category: test_tools }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    select "Test Tools", from: "Skill Category"
    fill_in "Aliases", with: "Selenium WebDriver, WebDriver"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: true

  describe "Happy Path (Skill)" do
    it "Shows the category and aliases" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      click_button "Create Skill"

      expect(page).to have_selector("[data-testid='detail-skill-category']", text: "Test Tools")
      expect(page).to have_selector("[data-testid='detail-aliases']", text: "Selenium WebDriver, WebDriver")
    end

    it "Makes a Skill a version of another and shows the family on both pages" do
      windows = create(:dossier_skill, name: "Windows", skill_category: test_tools)
      create(:dossier_skill, name: "Windows Vista", skill_category: test_tools, parent: windows)
      xp = create(:dossier_skill, name: "Windows XP", skill_category: test_tools)
      sign_in_as(create(:user, :admin))
      visit edit_dossier_skill_path(xp)

      expect(page).not_to have_select("Version Of", with_options: [ "Windows Vista" ])
      select "Windows", from: "Version Of"
      click_button "Update Skill"

      expect(page).to have_selector("[data-testid='detail-version-of']", text: "Windows")
      visit dossier_skill_path(windows)
      expect(page).to have_selector("[data-testid='detail-versions']", text: "Windows Vista, Windows XP")
    end

    it "Lists Skills under their Skill Categories, both alphabetically" do
      methods = create(:dossier_skill_category, name: "Methodologies")
      create(:dossier_skill, name: "Selenium", skill_category: test_tools)
      create(:dossier_skill, name: "Cypress", skill_category: test_tools)
      create(:dossier_skill, name: "Scrum", skill_category: methods)
      visit index_path

      expect(all("[data-testid='reference-data-group']").map(&:text)).to eq([ "Methodologies (1)", "Test Tools (2)" ])
      expect(all("[data-testid='reference-data-name']").map(&:text)).to eq(%w[Scrum Cypress Selenium])
    end
  end
end
