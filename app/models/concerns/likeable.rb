# app/models/concerns/likeable.rb
module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  # nil for a guest, or a signed-in user who has no Like row, or one whose
  # Like row has been cleared (face: nil) — the view treats all three as
  # "nothing highlighted", so callers don't need to tell them apart.
  def current_user_face(user)
    return nil unless user
    likes.find_by(user: user)&.face
  end

  # Only counts rows with an actual reaction — a user who has never voted
  # (or who cleared their vote) contributes nothing, unlike the old
  # implicit-neutral-vote formula. nil means "nobody has reacted yet".
  def like_score
    return nil if reactions.empty?

    reactions.sum { |like| Like::FACES[like.face][:points] }.to_f / reactions.count
  end

  def like_score_face
    score = like_score
    return nil unless score

    target_points = score.round.clamp(1, 5)
    Like::FACES.find { |_, data| data[:points] == target_points }.first
  end

  def total_reactions
    reactions.count
  end

  # One row per Like::FACES entry, grinning-to-angry, each with a count and
  # a bar width as a percentage of total_reactions — feeds the breakdown
  # popup (see Review.png in the planning doc). Percentages are all 0 when
  # there are no reactions, rather than dividing by zero.
  def reaction_breakdown
    total = total_reactions

    Like::FACES.map do |face, data|
      count = reactions.count { |like| like.face == face }
      percentage = total.zero? ? 0.0 : (count.to_f / total * 100).round(1)
      { face: face, icon: data[:icon], count: count, percentage: percentage }
    end
  end

  private

  def reactions
    likes.reject { |like| like.face.nil? }
  end
end
