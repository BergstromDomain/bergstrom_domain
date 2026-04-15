# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  # ── Associations ──────────────────────────────────────────────────────────
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
