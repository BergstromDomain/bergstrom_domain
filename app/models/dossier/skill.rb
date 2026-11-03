# app/models/dossier/skill.rb
class Dossier::Skill < ApplicationRecord
  include Dossier::NamedReferenceData

  belongs_to :skill_category
  has_many :assignment_skills, dependent: :restrict_with_error
  has_many :achievement_skills, dependent: :restrict_with_error

  before_validation :tidy_aliases

  validate :aliases_are_not_other_skills
  validate :name_is_not_another_skills_alias

  def self.find_by_name_or_alias(text)
    text = text.to_s.strip.downcase
    return if text.empty?

    find_by("LOWER(name) = :text OR :text = ANY (SELECT LOWER(a) FROM unnest(aliases) AS a)", text: text)
  end

  # An unsaved Skill for a name typed in a Tech Stack or Achievement, to be
  # filed properly later.
  def self.new_uncategorised(name)
    new(name: name, skill_category: Dossier::SkillCategory.find_or_create_by!(name: Dossier::TechStack::UNCATEGORISED))
  end

  # Folds a duplicate into target: Tech Stack and Achievement links move
  # across (dropping any target already has), this Skill's name and aliases
  # become target's aliases, and this Skill is deleted.
  def merge_into!(target)
    raise ArgumentError, "A Skill can't be merged into itself" if target == self

    transaction do
      move_links(assignment_skills, target, :assignment_id, :stack_slot)
      move_links(achievement_skills, target, :achievement_id)
      names = [ name, *aliases ]
      target.description ||= description
      destroy!
      target.update!(aliases: target.aliases + names)
    end
  end

  def aliases_text
    aliases.join(", ")
  end

  def aliases_text=(text)
    self.aliases = text.to_s.split(",")
  end

  private

  def move_links(links, target, *keys)
    links.each do |link|
      taken = links.klass.exists?(link.slice(*keys).merge(skill_id: target.id))
      taken ? link.destroy! : link.update!(skill: target)
    end
    links.reset
  end

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
