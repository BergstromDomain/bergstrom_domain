# app/models/concerns/classifiable.rb
module Classifiable
  extend ActiveSupport::Concern

  included do
    # ── Enum ───────────────────────────────────────────────────────────────
    enum :classification, {
      restricted:   "restricted",
      contacts:     "contacts",
      unrestricted: "unrestricted"
    }, validate: true

    # ── Associations ───────────────────────────────────────────────────────
    belongs_to :user

    # ── Validations ────────────────────────────────────────────────────────
    validates :classification, presence: true
    validates :user, presence: true

    # ── Scopes ─────────────────────────────────────────────────────────────
    scope :visible_to_visitors, -> { where(classification: "unrestricted") }
    scope :visible_to_users,    -> { where(classification: %w[unrestricted contacts]) }
    scope :visible_to_admins,   -> { all }
  end
end
