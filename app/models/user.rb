# app/models/user.rb
class User < ApplicationRecord
  include Roleable

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :sessions, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :contact_users, through: :contacts, source: :contact

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
end
