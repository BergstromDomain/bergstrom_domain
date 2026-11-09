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

      # Defined on the class, not in this module: the friendly_id call above
      # includes FriendlyId::Slugged after this module, so a module method
      # would be shadowed by Slugged's "only when blank" default and a
      # renamed record would keep its old slug.
      def should_generate_new_friendly_id?
        name_changed? || super
      end
    end

    def to_toast_label
      name
    end
  end
end
