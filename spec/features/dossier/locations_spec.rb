# spec/features/dossier/locations_spec.rb
require "rails_helper"

RSpec.describe "Dossier Locations", type: :feature do
  let(:factory)     { :dossier_location }
  let(:model)       { Dossier::Location }
  let(:singular)    { "Location" }
  let(:plural)      { "Locations" }
  let(:index_path)  { dossier_locations_path }
  let(:new_path)    { new_dossier_location_path }
  let(:record_name) { "Falun, Sweden" }

  def sortable_attributes(text) = { city: text, country: "Sweden" }
  def fill_name(text) = fill_in("City", with: text.split(", ").first.to_s)

  def fill_valid_form
    fill_in "City",    with: "Falun"
    fill_in "Country", with: "Sweden"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false
end
