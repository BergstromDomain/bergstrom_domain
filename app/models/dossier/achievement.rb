# app/models/dossier/achievement.rb

# A CV bullet point: one terse text under an Assignment ("Ran daily defect
# triage…"), with an optional impact, the situation it came from (for
# interview-style examples, never on a CV), an importance (1–5, which later picks
# a CV's default bullets) and Skill tags. Kept in the user's order within its
# Assignment. user_id mirrors the Assignment's owner (for Policy and
# Classifiable). Deleting is soft; PurgeDeletedDossierAchievementsJob removes
# them after DELETION_RETENTION_PERIOD.
class Dossier::Achievement < ApplicationRecord
  include Classifiable
  include Dossier::SkillTags
  include Dossier::CvSelectable

  DELETION_RETENTION_PERIOD = 30.days
  IMPORTANCE = (1..5)

  belongs_to :assignment
  has_many :achievement_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :achievement
  has_many :skills, through: :achievement_skills
  skill_tags :achievement_skills, soft_boxes: true

  normalizes :text, with: ->(value) { value.strip }
  normalizes :impact, :situation, with: ->(value) { value.strip.presence }

  before_validation { self.user_id = assignment&.user_id }
  before_create { self.position ||= (siblings.maximum(:position) || 0) + 1 }

  validates :text, presence: true
  validates :importance, inclusion: { in: IMPORTANCE }

  scope :kept,      -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }
  scope :in_order,  -> { order(:position, :id) }

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

  def soft_delete!
    update_columns(deleted_at: Time.current)
  end

  def restore!
    update_columns(deleted_at: nil)
  end

  # Deleted itself, or its Assignment or Engagement is (deleted_at alone is
  # the Achievement's own soft delete).
  def hidden?
    deleted_at.present? || assignment&.hidden?
  end

  def purge_at
    deleted_at + DELETION_RETENTION_PERIOD if deleted_at
  end

  # The situation is private: only the owner and Admins see it, never on a CV.
  def situation_visible_to?(user)
    situation.present? && user.present? && (user_id == user.id || user.can_administer?)
  end

  def to_toast_label
    text.to_s.truncate(60, separator: " ")
  end

  private

  def siblings
    self.class.where(assignment_id: assignment_id)
  end
end
