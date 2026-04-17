# app/models/concerns/classifiable.rb
module Classifiable
  extend ActiveSupport::Concern

  included do
    enum :classification, {
      restricted:   "restricted",
      contacts:     "contacts",
      unrestricted: "unrestricted"
    }, validate: true

    belongs_to :user

    validates :classification, presence: true
    validates :user, presence: true

    scope :visible_to_visitors, -> { where(classification: "unrestricted") }
    scope :visible_to_admins,   -> { all }
  end

  class_methods do
    def visible_to_users(user)
      contact_owner_ids = Contact.confirmed_contact_ids_for(user)

      where(classification: "unrestricted")
        .or(
          where(
            classification: "contacts",
            user_id: [ user.id ] + contact_owner_ids
          )
        )
    end
  end
end
