# app/models/recipe.rb
class Recipe < ApplicationRecord
  include Classifiable
  include MarkdownRenderable

  extend FriendlyId
  # :title is only unique per owner, so a second owner's same-titled recipe
  # falls back to [:title, :user_id] — mirrors BlogPost.
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  # Required on every save, drafts included (the columns are NOT NULL too) —
  # see "DECISIONS (2026-10-11)" in docs/context-prompts/active/App_-_Cookbook.md.
  # Kept as presence validations on optional associations, rather than
  # required belongs_to, so the errors read "can't be blank" like the rest.
  belongs_to :cuisine,   optional: true
  belongs_to :food_type, optional: true
  belongs_to :language,  optional: true

  has_one_attached :recipe_image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  enum :format, { raw: "raw", formatted: "formatted" }, validate: true

  validates :title, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :cuisine, :food_type, :language, presence: true
  validates :serves, :makes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :body, presence: true, if: :published?

  validates :recipe_image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  scope :published, -> { where.not(published_at: nil) }
  scope :draft,     -> { where(published_at: nil) }
  scope :kept,      -> { where(deleted_at: nil) }
  scope :discarded, -> { where.not(deleted_at: nil) }

  # Drafts are visible only to their owner, whatever their classification;
  # Classifiable's rules govern published recipes. Soft-deleted recipes never
  # surface here (only on an admin-only Deleted Recipes page, a later block).
  scope :visible_to_visitors, -> { published.kept.where(classification: "unrestricted") }
  scope :visible_to_admins,   -> { kept }

  def self.visible_to_users(user)
    super.published.kept.or(kept.draft.where(user_id: user.id))
  end

  def published?
    published_at.present?
  end

  # The Read page shows "Makes: 24" when Makes is set, otherwise "Serves: 4" —
  # still labelled Serves when both are blank.
  def portions
    makes.present? ? [ "Makes", makes ] : [ "Serves", serves ]
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def slug_candidates
    [
      :title,
      [ :title, :user_id ]
    ]
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    title
  end
end
