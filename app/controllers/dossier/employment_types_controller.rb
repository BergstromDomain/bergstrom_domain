# app/controllers/dossier/employment_types_controller.rb
class Dossier::EmploymentTypesController < Dossier::ReferenceDataController
  # Also lists the signed-in user's own kept Engagements of this type, newest
  # first, each with its Assignments; nil for a visitor or when there are none.
  def show
    super
    return unless current_user

    @engagements = current_user.dossier_engagements.kept.where(employment_type: @record)
                               .includes(employer: { logo_attachment: :blob }, assignments: { client: { logo_attachment: :blob } })
                               .order(start_on: :desc).to_a.presence
  end

  private

  def experience_slices = [ [ "Years", :employment_type ] ]

  def model_class          = Dossier::EmploymentType
  def show_panels          = "dossier/employment_types/engagements"
  def permitted_attributes = %i[name description permanent personal]
  def subtitle             = "How an employer engaged you. A permanent type gives its Engagement one Assignment automatically; a personal type is for your own projects."

  def details(record)
    [ [ "Permanent", record.permanent? ? "Yes" : "No", "permanent" ],
      [ "Personal",  record.personal? ? "Yes" : "No", "personal" ] ]
  end
end
