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

  # A category a guide page belongs to, not a 1-page-per-app slot — many
  # pages can share a section (e.g. "Classification" and "Sign Up" both
  # under :core), each distinguished by its own title. Recipes/Photo Album
  # are left out for now since neither app exists yet; add them back once
  # they do.
  enum :app_section, {
    core:          "core",
    event_tracker: "event_tracker",
    blog_posts:    "blog_posts",
    admin:         "admin"
  }, validate: true

  # Brand-facing labels for app_section — the enum's own values stay
  # technical/aligned with AppPermission#app_name and Policy#app_name_for;
  # only the display differs. Mirrors this codebase's existing brand-vs-
  # technical split (CLAUDE.md: "Chronicle" is BlogPost's brand, "Occasions"
  # is Event_Tracker's).
  APP_SECTION_LABELS = {
    "core"          => "Core",
    "event_tracker" => "Occasions",
    "blog_posts"    => "Chronicle",
    "admin"         => "Admin"
  }.freeze

  validates :title,       presence: true, uniqueness: { case_sensitive: false }
  validates :app_section, presence: true
  validates :body,        presence: true

  # Plain title/body substring search — deliberately not a JQL-style query
  # language like BlogPostFilter's (that was built as a reusable engine on
  # purpose); a documentation search box doesn't need that complexity.
  def self.search(query)
    return all if query.blank?

    term = "%#{sanitize_sql_like(query)}%"
    where("title ILIKE :term OR body ILIKE :term", term: term)
  end

  def app_section_label
    APP_SECTION_LABELS.fetch(app_section)
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    title
  end
end
