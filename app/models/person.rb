# app/models/person.rb
class Person < ApplicationRecord
  include Classifiable
  include Auditable

  extend FriendlyId
  friendly_id :full_name, use: [ :slugged, :history ]

  # SQL fragment for the A–Z bucketing rule: last_name if present,
  # first_name otherwise. Shared between the scope below and the
  # `available_letters` lookup so the two can never disagree.
  BUCKET_LETTER_SQL = "UPPER(LEFT(COALESCE(NULLIF(last_name, ''), first_name), 1))".freeze

  # Explicit array, not a Range — "Z".succ is "AA", not "Å", so a Range
  # can't be extended to include the three extra Swedish letters.
  BUCKET_LETTERS = ("A".."Z").to_a + %w[Å Ä Ö]

  # A LinkedIn profile URL's username: linkedin.com/in/<username>.
  LINKEDIN_PROFILE = %r{linkedin\.com/in/([^/?#]+)}i

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :event_people, dependent: :destroy
  has_many :events, through: :event_people
  has_many :person_mutes, dependent: :destroy
  has_many :person_social_media_accounts, dependent: :destroy
  has_many :social_media_platforms, through: :person_social_media_accounts
  # Dossier: the Assignments' Colleagues and Staff this Person is. A Person
  # who is one can't be deleted until they're removed there.
  has_many :dossier_colleagues, class_name: "Dossier::Colleague", dependent: nil
  has_many :dossier_staff_members, class_name: "Dossier::StaffMember", dependent: nil
  has_many :dossier_engagement_colleagues, class_name: "Dossier::EngagementColleague", dependent: nil

  before_destroy :keep_if_a_dossier_contact, prepend: true

  accepts_nested_attributes_for :person_social_media_accounts,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["social_media_platform_id"].blank? }

  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  normalizes :work_email, with: ->(value) { value.strip.presence }

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validates :work_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validate  :full_name_must_be_unique
  validate  :social_media_platforms_must_be_unique

  validates :image,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :by_letter, ->(letter) { where("#{BUCKET_LETTER_SQL} = ?", letter.to_s.upcase) }

  # ── Class methods ─────────────────────────────────────────────────────────
  # Distinct set of bucket letters actually present in a given scope —
  # used to decide which A–Z tabs are clickable vs. disabled.
  def self.available_letters(scope = all)
    scope.distinct.pluck(Arel.sql(BUCKET_LETTER_SQL)).compact
  end

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [ first_name, middle_name, last_name ].reject(&:blank?).join(" ")
  end

  def bucket_letter
    (last_name.presence || first_name).to_s.first&.upcase
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    full_name
  end

  # ── LinkedIn ──────────────────────────────────────────────────────────────
  # The Person's LinkedIn account (Social Media) as a profile URL: its
  # username is the part after linkedin.com/in/, or a whole URL that isn't one.
  def linkedin_url
    username = linkedin_account&.username
    return if username.blank?

    username.match?(%r{\Ahttps?://}i) ? username : "https://www.linkedin.com/in/#{username}"
  end

  # A profile URL (or just its username) sets the LinkedIn account; blank
  # removes it. Saved with the Person.
  def linkedin_url=(value)
    value = value.to_s.strip
    account = linkedin_account
    if value.empty?
      account&.mark_for_destruction
    else
      account ||= person_social_media_accounts.build(social_media_platform: SocialMediaPlatform.linkedin)
      account.username = value[LINKEDIN_PROFILE, 1] || value
    end
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    first_name_changed? || middle_name_changed? || last_name_changed? || super
  end

  private

  def linkedin_account
    person_social_media_accounts.find do |account|
      !account.marked_for_destruction? && account.social_media_platform&.name&.casecmp?("LinkedIn")
    end
  end

  def keep_if_a_dossier_contact
    return unless dossier_colleagues.exists? || dossier_staff_members.exists? || dossier_engagement_colleagues.exists?

    errors.add(:base, "#{full_name} is a Colleague or Staff member in Dossier: remove them there first.")
    throw :abort
  end

  # PersonSocialMediaAccount's own uniqueness validation only queries the
  # database, so it can't see two not-yet-saved sibling rows built together
  # via nested attributes (e.g. two rows added in the same form submission
  # before either is persisted) — checked here, in memory, instead.
  def social_media_platforms_must_be_unique
    platform_ids = person_social_media_accounts.reject(&:marked_for_destruction?)
                                                 .map(&:social_media_platform_id).compact
    return if platform_ids.uniq.size == platform_ids.size

    errors.add(:person_social_media_accounts, "can only include one account per platform")
  end

  def full_name_must_be_unique
    return if first_name.blank?
    scope = Person.where.not(id: id.to_i)
    errors.add(:base, "Full name has already been taken") if scope.any? { |p| p.full_name.casecmp?(full_name) }
  end
end
