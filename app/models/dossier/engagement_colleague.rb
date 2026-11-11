# app/models/dossier/engagement_colleague.rb

# Someone you worked with during an Engagement but on no Assignment you
# shared, such as a fellow consultant at the same employer (see
# Dossier::ContactDetails). Private to the Engagement's owner and Admins
# (Engagement#private_details_visible_to?), and never on a CV.
class Dossier::EngagementColleague < ApplicationRecord
  include Dossier::ContactDetails

  belongs_to :engagement

  validates :person, uniqueness: { scope: :engagement_id, message: "is already a Colleague on this Engagement" }
end
