# app/models/social_media_platform.rb
class SocialMediaPlatform < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  has_many :person_social_media_accounts, dependent: :restrict_with_error

  has_one_attached :logo do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :url,  presence: true
  validate  :url_must_be_http_or_https

  validates :logo,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be a JPEG, PNG, or WebP" },
    size:         { less_than: 5.megabytes, message: "must be smaller than 5MB" }

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  # Identifying label used by Toastable — see docs/context-prompts/active/New_Feature_Toasts.md
  def to_toast_label
    name
  end

  private

  def url_must_be_http_or_https
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:url, "must be a valid http(s) URL")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "must be a valid http(s) URL")
  end
end
