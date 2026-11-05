# app/controllers/dossier/organisations_controller.rb
class Dossier::OrganisationsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true

  # The signed-in user's own Credentials this Organisation issued, of any type.
  def show
    super
    return unless current_user

    @credentials = current_user.dossier_credentials.kept.where(provider: @record)
                               .includes(:provider).newest_first.to_a
  end

  private

  def model_class          = Dossier::Organisation
  def permitted_attributes = %i[name abbreviation industry_id website_url description]
  def subtitle             = "Employers, clients, education providers and credential issuers, shared by every Dossier."
  def show_panels          = "dossier/organisations/credentials"

  def details(record)
    website = record.website_url && helpers.link_to(record.website_url, record.website_url, rel: "noopener", target: "_blank")
    [ [ "Abbreviation", record.abbreviation, "abbreviation" ],
      [ "Industry",     record.industry&.name, "industry" ],
      [ "Website",      website, "website" ] ]
  end

  def assignments_for(record, assignments) = assignments.where(client: record)
end
