# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :blog_post, counter_cache: true
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies

  has_many :replies, -> { order(created_at: :asc) },
    class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  validates :body, presence: true
  validate  :parent_must_be_top_level

  scope :top_level,       -> { where(parent_id: nil) }
  scope :threads_ordered, -> { top_level.order(created_at: :desc) }

  private

  # Comments are only ever 2 levels deep (thread + flat replies) —
  # CommentsController#resolve_parent flattens a reply-to-a-reply onto the
  # thread before saving, so this only ever fires against a forged request
  # that bypasses that resolution.
  def parent_must_be_top_level
    errors.add(:parent, "must be a top-level comment") if parent&.parent_id.present?
  end
end
