# spec/features/dossier/roles_spec.rb
require "rails_helper"

RSpec.describe "Dossier Roles", type: :feature do
  let(:factory)     { :dossier_role }
  let(:model)       { Dossier::Role }
  let(:singular)    { "Role" }
  let(:plural)      { "Roles" }
  let(:index_path)  { dossier_roles_path }
  let(:new_path)    { new_dossier_role_path }
  let(:record_name) { "Test Manager" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)
  def fill_valid_form = fill_name(record_name)

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false
end
