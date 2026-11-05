# app/controllers/dossier/employment_types_controller.rb
class Dossier::EmploymentTypesController < Dossier::ReferenceDataController
  private

  def experience_slices = [ [ "Years", :employment_type ] ]

  def model_class          = Dossier::EmploymentType
  def permitted_attributes = %i[name description permanent personal]
  def subtitle             = "How an employer engaged you. A permanent type gives its Engagement one Assignment automatically; a personal type is for your own projects."

  def details(record)
    [ [ "Permanent", record.permanent? ? "Yes" : "No", "permanent" ],
      [ "Personal",  record.personal? ? "Yes" : "No", "personal" ] ]
  end
end
