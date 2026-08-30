# app/models/blog_post.rb
class BlogPost < ApplicationRecord
  include Classifiable

  # Everything Quill's stock toolbar (Block 2's editor scope) can produce.
  # Rails' default sanitizer allowlist drops <u>/<s> and any table, so a
  # plain `sanitize(rendered_body)` would silently lose formatting the editor
  # shows the author — extend the list explicitly instead. Revisit when the
  # media/embeds block adds tables/images/video to what the editor can
  # actually produce.
  RENDERED_BODY_ALLOWED_TAGS       = %w[h1 h2 h3 h4 h5 h6 p br strong em u s blockquote ol ul li a code pre].freeze
  RENDERED_BODY_ALLOWED_ATTRIBUTES = %w[href].freeze

  extend FriendlyId
  # :title alone isn't globally unique (only unique per user), so two
  # different users sharing a title need a fallback candidate — user_id is
  # available before the record is saved (unlike :id, which isn't assigned
  # yet), and is guaranteed to disambiguate since [:title, :user_id] is
  # itself the app's own uniqueness constraint.
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  belongs_to :blog_category, optional: true
  has_many :blog_post_authors, dependent: :destroy
  has_many :authors, through: :blog_post_authors, source: :user

  has_one_attached :blog_image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  enum :format, { raw: "raw", formatted: "formatted" }, validate: true

  after_create :add_primary_author_as_blog_post_author

  validates :title, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validate  :topic_requires_sub_category

  validates :blog_image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  scope :published, -> { where.not(published_at: nil) }
  scope :draft,      -> { where(published_at: nil) }
  scope :kept,       -> { where(deleted_at: nil) }
  scope :discarded,  -> { where.not(deleted_at: nil) }

  # Drafts are visible only to their authors, regardless of classification —
  # Classifiable's normal rules only govern published posts.
  scope :visible_to_visitors, -> { published.where(classification: "unrestricted") }
  scope :visible_to_admins,   -> { kept }

  def self.visible_to_users(user)
    own_draft_ids = BlogPostAuthor.where(user_id: user.id).select(:blog_post_id)

    super.published
      .or(kept.draft.where(id: own_draft_ids))
  end

  def published?
    published_at.present?
  end

  def rendered_body
    self.class.render_markdown(body)
  end

  # header_ids: nil turns off Commonmarker's default heading-anchor-link
  # generation (it's on by default, even with header_ids left unset) — Quill
  # has no use for those anchors and they'd just clutter the editor/reader.
  def self.render_markdown(markdown)
    Commonmarker.to_html(markdown.to_s, options: { render: { unsafe: true }, extension: { header_ids: nil } })
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

  private

  def add_primary_author_as_blog_post_author
    blog_post_authors.find_or_create_by!(user: user)
  end

  def topic_requires_sub_category
    errors.add(:sub_category, "must be present if Topic is set") if topic.present? && sub_category.blank?
  end
end
