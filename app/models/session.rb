# app/models/session.rb
class Session < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :user
end
