# spec/features/dossier/skill_categories_spec.rb
require "rails_helper"

RSpec.describe "Dossier Skill Categories", type: :feature do
  let(:factory)     { :dossier_skill_category }
  let(:model)       { Dossier::SkillCategory }
  let(:singular)    { "Skill Category" }
  let(:plural)      { "Skill Categories" }
  let(:index_path)  { dossier_skill_categories_path }
  let(:new_path)    { new_dossier_skill_category_path }
  let(:record_name) { "Test Tools" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)
  def fill_valid_form = fill_name(record_name)

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false
end
