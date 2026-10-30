# app/controllers/dossier/employment_types_controller.rb
class Dossier::EmploymentTypesController < Dossier::ReferenceDataController
  private

  def model_class          = Dossier::EmploymentType
  def permitted_attributes = %i[name description permanent]
  def subtitle             = "How an employer engaged you. A permanent type gives its Engagement one Assignment automatically."

  def details(record)
    [ [ "Permanent", record.permanent? ? "Yes" : "No", "permanent" ] ]
  end
end
