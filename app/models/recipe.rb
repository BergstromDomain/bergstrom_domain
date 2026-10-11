# app/models/recipe.rb
class Recipe < ApplicationRecord
  include Classifiable
  include MarkdownRenderable
  include Likeable

  # Soft-deleted recipes are kept this long before PurgeDeletedRecipesJob
  # removes them for good — mirrors BlogPost.
  DELETION_RETENTION_PERIOD = 30.days

  extend FriendlyId
  # :title is only unique per owner, so a second owner's same-titled recipe
  # falls back to [:title, :user_id] — mirrors BlogPost.
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  RENDERED_BODY_ALLOWED_TAGS       = %w[h1 h2 h3 h4 h5 h6 p br strong em u s blockquote ol ul li a code pre img span].freeze
  RENDERED_BODY_ALLOWED_ATTRIBUTES = %w[href src alt style lang].freeze

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

  has_many :ingredient_sections, -> { order(:position) }, dependent: :destroy, inverse_of: :recipe
  # A list with no heading and only blank rows is the form's untouched
  # starting list — dropped rather than saved empty.
  accepts_nested_attributes_for :ingredient_sections, allow_destroy: true,
    reject_if: ->(attrs) {
      attrs["heading"].blank? &&
        (attrs["ingredients_attributes"] || {}).values.all? do |row|
          row.slice("quantity", "measurement", "name", "comment").values.all?(&:blank?)
        end
    }

  enum :format, { raw: "raw", formatted: "formatted" }, validate: true

  validates :title, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :cuisine, :food_type, :language, presence: true
  validates :serves, :makes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :body, presence: true, if: :published?
  validate :must_have_an_ingredient, if: :published?

  before_validation :assign_ingredient_positions

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

  def purge_at
    deleted_at + DELETION_RETENTION_PERIOD if deleted_at
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

  private

  # A published recipe needs something to cook with — see "DECISIONS (Block 5)"
  # in docs/context-prompts/active/App_-_Cookbook.md. Checked on every save
  # while published, so an edit can't strip the last ingredient either.
  def must_have_an_ingredient
    has_one = ingredient_sections.reject(&:marked_for_destruction?).any? do |section|
      section.ingredients.reject(&:marked_for_destruction?).any?
    end
    errors.add(:base, "Add at least one ingredient before publishing") unless has_one
  end

  # Lists and rows are saved in the order the form submitted them.
  def assign_ingredient_positions
    ingredient_sections.reject(&:marked_for_destruction?).each_with_index do |section, i|
      section.position = i
      section.ingredients.reject(&:marked_for_destruction?).each_with_index do |ingredient, j|
        ingredient.position = j
      end
    end
  end
end
