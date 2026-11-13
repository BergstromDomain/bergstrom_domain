# app/controllers/dossier/organisations_controller.rb
class Dossier::OrganisationsController < Dossier::ReferenceDataController
  self.content_creators_can_create = true

  def index
    @records = model_class.alphabetical.includes(logo_attachment: :blob)
  end

  # The Skills it makes (public), and the signed-in user's own Credentials
  # this Organisation issued, of any type, and their own Assignments where
  # it's a Vendor or Customer.
  def show
    super
    # Sorted by shown name ("Excel" before "Microsoft Project").
    @products = @record.products.to_a.sort_by { |skill| skill.display_name.downcase }
    return unless current_user

    @credentials = current_user.dossier_credentials.kept.where(provider: @record)
                               .includes(:provider).newest_first.to_a
    own = Dossier::Assignment.kept.where(engagement_id: current_user.dossier_engagements.kept.select(:id))
    @partner_links = Dossier::AssignmentPartner.where(organisation: @record, assignment_id: own.select(:id))
                                               .includes(assignment: :client).to_a
                                               .sort_by { |link| link.assignment.start_on }.reverse.group_by(&:kind)
  end

  private

  def experience_slices = [ [ "As Employer", :employer ], [ "As Client", :client ] ]

  def model_class          = Dossier::Organisation
  def permitted_attributes = %i[name abbreviation industry_id website_url description logo remove_logo]
  def subtitle             = "Employers, clients, education providers and credential issuers, shared by every Dossier."
  def show_panels          = "dossier/organisations/panels"

  def details(record)
    website = record.website_url && helpers.link_to(record.website_url, record.website_url, rel: "noopener", target: "_blank")
    [ [ "Abbreviation", record.abbreviation, "abbreviation" ],
      [ "Industry",     record.industry&.name, "industry" ],
      [ "Website",      website, "website" ] ]
  end

  def assignments_for(record, assignments) = assignments.where(client: record)
end
