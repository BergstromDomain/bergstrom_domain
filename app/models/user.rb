# app/models/user.rb
class User < ApplicationRecord
  include Roleable

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :sessions, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :contact_users, through: :contacts, source: :contact

  has_many :person_mutes, dependent: :destroy
  has_many :muted_people, through: :person_mutes, source: :person
  has_many :event_mutes, dependent: :destroy
  has_many :muted_events, through: :event_mutes, source: :event
  has_many :event_type_mutes, dependent: :destroy
  has_many :muted_event_types, through: :event_type_mutes, source: :event_type

  # ── Active Storage ────────────────────────────────────────────────────────
  has_one_attached :profile_image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  # ── Enums ─────────────────────────────────────────────────────────────────
  enum :status, {
    pending:   "pending",
    active:    "active",
    suspended: "suspended"
  }, validate: true

  # ── Validations ───────────────────────────────────────────────────────────
  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :status,     presence: true

  # ── Helper methods ───────────────────────────────────────────────────────────
  def can_export?
    content_creator? || admin? || system_admin?
  end
end
