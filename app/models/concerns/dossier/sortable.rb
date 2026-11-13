# app/models/concerns/dossier/sortable.rb

# A hand-made order among siblings (an Assignment's Achievements, an
# Engagement's Assignments), kept in a position column. The including model
# defines siblings, and sets a new record's position.
module Dossier::Sortable
  extend ActiveSupport::Concern

  included do
    scope :in_order, -> { order(:position, :id) }
  end

  # Swaps places with the kept neighbour above (:up) or below (:down); false
  # when already at that end.
  def move!(direction)
    neighbours = siblings.kept.where.not(id: id)
    neighbour = if direction.to_s == "up"
      neighbours.where(position: ...position).order(position: :desc).first
    else
      neighbours.where("position > ?", position).order(:position).first
    end
    return false unless neighbour

    transaction do
      mine, theirs = position, neighbour.position
      update_columns(position: theirs)
      neighbour.update_columns(position: mine)
    end
    true
  end
end
