# app/models/dossier/colleague.rb

# Someone you worked with on an Assignment (see Dossier::ContactDetails).
# Private to the Assignment's owner and Admins
# (Assignment#private_details_visible_to?), whatever the Assignment's
# classification, and never on a CV.
class Dossier::Colleague < ApplicationRecord
  include Dossier::ContactDetails

  belongs_to :assignment
end
