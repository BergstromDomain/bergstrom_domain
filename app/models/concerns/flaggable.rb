# app/models/concerns/flaggable.rb

# A reference-data row shown as a flag emoji (e.g. 🇸🇪) with a small Lucide
# badge over it — Cookbook's Cuisine and Language (Design Question-3 in
# docs/context-prompts/active/Cookbook_App.md). Any single emoji is
# accepted, not only national flags, so a regional Cuisine like
# "Mediterranean" can use 🌍.
module Flaggable
  extend ActiveSupport::Concern

  EMOJI = /\A(?:\p{Extended_Pictographic}|\p{Regional_Indicator})/

  included do
    validates :flag, presence: true
    validate  :flag_must_be_a_single_emoji
  end

  private

  def flag_must_be_a_single_emoji
    return if flag.blank?
    return if flag.grapheme_clusters.size == 1 && flag.match?(EMOJI)

    errors.add(:flag, "must be a single emoji, e.g. 🇸🇪")
  end
end
