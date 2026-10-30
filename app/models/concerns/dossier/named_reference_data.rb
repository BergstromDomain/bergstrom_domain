# app/models/concerns/dossier/named_reference_data.rb

# Shared behaviour for Dossier reference data identified by a unique name:
# case-insensitive uniqueness, an optional description, friendly_id slugs and
# the Toastable label.
module Dossier
  module NamedReferenceData
    extend ActiveSupport::Concern

    included do
      extend FriendlyId
      friendly_id :name, use: [ :slugged, :history ]

      normalizes :name, with: ->(name) { name.strip }

      validates :name, presence: true, uniqueness: { case_sensitive: false }

      scope :alphabetical, -> { order(Arel.sql("LOWER(#{table_name}.name) ASC")) }
    end

    def should_generate_new_friendly_id?
      name_changed? || super
    end

    def to_toast_label
      name
    end
  end
end
