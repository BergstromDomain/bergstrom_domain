# app/models/concerns/dossier/cv_selectable.rb

# A record a CV Variant can tick or untick (Engagement, Assignment,
# Achievement, Skill, Credential, Contribution): its item rows go with it.
module Dossier
  module CvSelectable
    extend ActiveSupport::Concern

    included do
      has_many :cv_variant_items, class_name: "Dossier::CvVariantItem", as: :item, dependent: :delete_all
    end
  end
end
