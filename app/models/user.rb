# app/models/user.rb
class User < ApplicationRecord
  include Roleable

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :sessions, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :contact_users, through: :contacts, source: :contact

  # ── Validations ───────────────────────────────────────────────────────────
  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
end
