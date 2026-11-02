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
