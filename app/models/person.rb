class Person < ApplicationRecord
  before_validation :generate_slug, on: :create

  # Validations
  validates :firstname, presence: true
  validates :firstname, uniqueness: { scope: :lastname }
  validates :slug, uniqueness: true, allow_nil: true

  # Scopes
  scope :alphabetical, -> {
    order(Arel.sql("COALESCE(lastname, firstname), firstname"))
  }

  scope :search_by_name, ->(query) {
    where(
      "firstname ILIKE :q OR lastname ILIKE :q",
      q: "%#{query}%"
    )
  }

  # Virtual attributes
  def fullname
    [ firstname, middlename, lastname ].compact_blank.join(" ")
  end

  # Image helper methods
  def thumbnail_url
    return if thumbnail_image.blank?
    "/images/people/thumbnails/#{thumbnail_image}"
  end

  def full_image_url
    return if full_image.blank?
    "/images/people/full/#{full_image}"
  end

  # Override to_param so Rails automatically uses slug in URLs
  def to_param
    slug
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = fullname.parameterize
  end
end
