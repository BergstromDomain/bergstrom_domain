# app/models/dossier/staff_member.rb

# Someone at an Assignment's Vendor or Customer (see Dossier::ContactDetails),
# e.g. PwC's Delivery Lead on project Alpha. Private to the Assignment's owner
# and Admins and never on a CV.
class Dossier::StaffMember < ApplicationRecord
  include Dossier::ContactDetails

  belongs_to :assignment_partner, class_name: "Dossier::AssignmentPartner"

  delegate :assignment, to: :assignment_partner
end
