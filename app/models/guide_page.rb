# app/models/guide_page.rb
class GuidePage < ApplicationRecord
  include MarkdownRenderable

  # Same allowlist as BlogPost's — same Commonmarker rendering pipeline
  # (MarkdownRenderable), same need to keep headings/lists/code/syntax-
  # highlighting spans through Rails' sanitizer. Kept as GuidePage's own
  # constant rather than sharing BlogPost's so the two can diverge later
  # (e.g. GuidePage has no image-upload feature yet) without coupling.
  RENDERED_BODY_ALLOWED_TAGS       = %w[h1 h2 h3 h4 h5 h6 p br strong em u s blockquote ol ul li a code pre img span].freeze
  RENDERED_BODY_ALLOWED_ATTRIBUTES = %w[href src alt style lang].freeze

  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  # One page per app section — mirrors this feature's DQ-2 decision (a core
  # landing page plus one page per app, not a single combined document).
  enum :app_section, {
    core:          "core",
    event_tracker: "event_tracker",
    blog_posts:    "blog_posts",
    recipes:       "recipes",
    photo_albums:  "photo_albums",
    admin:         "admin"
  }, validate: true

  validates :title,       presence: true, uniqueness: { case_sensitive: false }
  validates :app_section, presence: true, uniqueness: true
  validates :body,        presence: true

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    title
  end
end
