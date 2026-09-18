# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :likeable, polymorphic: true
  belongs_to :user

  # Spec's literal icon names ("face-grinning" etc.) don't exist in this
  # app's Lucide set — mapped to the closest real icons, same order and
  # sentiment gradient. Order matters: iterating this Hash is how the show
  # page renders the row grinning-to-angry.
  FACES = {
    "grinning"          => { icon: "laugh", points: 5, color: "#166534" },
    "slightly_smiling"  => { icon: "smile", points: 4, color: "#16a34a" },
    "neutral"           => { icon: "meh",   points: 3, color: "#ca8a04" },
    "slightly_frowning" => { icon: "frown", points: 2, color: "#ea580c" },
    "angry"             => { icon: "angry", points: 1, color: "#dc2626" }
  }.freeze

  # nil means "no reaction selected" (the default, and what a cleared Like
  # reverts to) — every real reaction is one of the FACES keys.
  enum :face, FACES.keys.index_with(&:itself), validate: { allow_nil: true }

  validates :user_id, uniqueness: { scope: %i[likeable_type likeable_id] }

  # Clears the user's reaction without destroying the row — a cleared Like
  # is distinguishable from a user who never reacted at all (no row exists).
  def clear!
    update!(face: nil)
  end
end
