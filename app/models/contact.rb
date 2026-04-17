# app/models/contact.rb
class Contact < ApplicationRecord
  belongs_to :user
  belongs_to :contact, class_name: "User"

  enum :status, {
    pending:   "pending",
    confirmed: "confirmed"
  }, validate: true

  validates :contact_id,
    uniqueness: { scope: :user_id, message: "has already been added" },
    numericality: { other_than: :user_id, message: "cannot be yourself" }, if: -> { user_id.present? }

  scope :confirmed, -> { where(status: "confirmed") }

  def self.confirmed_between?(user, other)
    confirmed
      .where(
        "(user_id = ? AND contact_id = ?) OR (user_id = ? AND contact_id = ?)",
        user.id, other.id, other.id, user.id
      )
      .exists?
  end

  def self.confirmed_contact_ids_for(user)
    ids_as_requester = confirmed.where(user_id: user.id).pluck(:contact_id)
    ids_as_recipient = confirmed.where(contact_id: user.id).pluck(:user_id)
    (ids_as_requester + ids_as_recipient).uniq
  end
end
