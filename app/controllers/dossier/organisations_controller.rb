# app/controllers/dossier/organisations_controller.rb
class Dossier::OrganisationsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true

  private

  def model_class          = Dossier::Organisation
  def permitted_attributes = %i[name abbreviation industry_id website_url description]
  def subtitle             = "Employers, clients, education providers and credential issuers, shared by every Dossier."

  def details(record)
    website = record.website_url && helpers.link_to(record.website_url, record.website_url, rel: "noopener", target: "_blank")
    [ [ "Abbreviation", record.abbreviation, "abbreviation" ],
      [ "Industry",     record.industry&.name, "industry" ],
      [ "Website",      website, "website" ] ]
  end
end
