# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :blog_post
  belongs_to :user

  # Spec's literal icon names ("face-grinning" etc.) don't exist in this
  # app's Lucide set — mapped to the closest real icons, same order and
  # sentiment gradient. Order matters: iterating this Hash is how the show
  # page renders the row grinning-to-angry.
  FACES = {
    "grinning"          => { icon: "laugh", points: 5 },
    "slightly_smiling"  => { icon: "smile", points: 4 },
    "neutral"           => { icon: "meh",   points: 3 },
    "slightly_frowning" => { icon: "frown", points: 2 },
    "angry"             => { icon: "angry", points: 1 }
  }.freeze

  enum :face, FACES.keys.index_with(&:itself), validate: true

  validates :user_id, uniqueness: { scope: :blog_post_id }
end
