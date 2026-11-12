# app/models/dossier/cv_variant_item.rb

# One record a CV Variant explicitly ticks (included) or unticks. With no
# row, Dossier::CvSelection's default rules decide.
class Dossier::CvVariantItem < ApplicationRecord
  ITEM_TYPES = %w[Dossier::Engagement Dossier::Assignment Dossier::Achievement Dossier::Skill Dossier::Credential
                  Dossier::Contribution].freeze

  belongs_to :cv_variant, class_name: "Dossier::CvVariant", inverse_of: :items
  belongs_to :item, polymorphic: true

  validates :item_type, inclusion: { in: ITEM_TYPES }
  validates :item_id, uniqueness: { scope: %i[cv_variant_id item_type] }
  validates :included, inclusion: { in: [ true, false ] }
end
