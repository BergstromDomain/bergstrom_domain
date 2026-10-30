# app/controllers/dossier/locations_controller.rb
class Dossier::LocationsController < Dossier::ReferenceDataController
  private

  def model_class          = Dossier::Location
  def permitted_attributes = %i[city country description]
  def subtitle             = "Where an Assignment's work was done."

  def details(record)
    [ [ "City", record.city, "city" ], [ "Country", record.country, "country" ] ]
  end
end
