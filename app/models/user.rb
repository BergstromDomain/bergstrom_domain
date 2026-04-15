# app/models/user.rb
class User < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  has_many :sessions, dependent: :destroy

  # ── Validations ───────────────────────────────────────────────────────────
  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
end
