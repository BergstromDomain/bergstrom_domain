# app/models/dossier/skill.rb
class Dossier::Skill < ApplicationRecord
  include Dossier::NamedReferenceData

  belongs_to :skill_category

  before_validation :tidy_aliases

  validate :aliases_are_not_other_skills
  validate :name_is_not_another_skills_alias

  def self.find_by_name_or_alias(text)
    text = text.to_s.strip.downcase
    return if text.empty?

    find_by("LOWER(name) = :text OR :text = ANY (SELECT LOWER(a) FROM unnest(aliases) AS a)", text: text)
  end

  def aliases_text
    aliases.join(", ")
  end

  def aliases_text=(text)
    self.aliases = text.to_s.split(",")
  end

  private

  def tidy_aliases
    own_name = name.to_s.strip.downcase
    self.aliases = aliases.map(&:strip).compact_blank
                          .uniq(&:downcase)
                          .reject { |a| a.downcase == own_name }
  end

  def others
    self.class.where.not(id: id)
  end

  def aliases_are_not_other_skills
    aliases.each do |a|
      errors.add(:aliases, "#{a} is already a Skill") if others.exists?([ "LOWER(name) = ?", a.downcase ])
    end
  end

  def name_is_not_another_skills_alias
    return if name.blank?

    owner = others.find_by("? = ANY (SELECT LOWER(a) FROM unnest(aliases) AS a)", name.strip.downcase)
    errors.add(:name, "is already an alias of #{owner.name}") if owner
  end
end
