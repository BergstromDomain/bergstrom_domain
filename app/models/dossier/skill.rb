# app/models/dossier/skill.rb
class Dossier::Skill < ApplicationRecord
  include Dossier::NamedReferenceData
  include Dossier::CvSelectable

  belongs_to :skill_category
  # Versions (Windows XP, Windows Vista) of a Skill (Windows): one level deep.
  belongs_to :parent, class_name: "Dossier::Skill", optional: true
  has_many :versions, -> { order(Arel.sql("LOWER(name)")) }, class_name: "Dossier::Skill", foreign_key: :parent_id,
                                                             inverse_of: :parent, dependent: :nullify
  has_many :assignment_skills, dependent: :restrict_with_error
  has_many :achievement_skills, dependent: :restrict_with_error
  has_many :credential_skills, dependent: :restrict_with_error
  # Who makes it (Microsoft for Project); show_vendor_in_name shows it as
  # "Microsoft Project".
  belongs_to :vendor, class_name: "Dossier::Organisation", optional: true, inverse_of: :products

  # A version's slug starts with its parent's name: /dossier/skills/windows-xp.
  friendly_id :slug_name, use: [ :slugged, :history ]

  before_validation :tidy_aliases
  after_update :reslug_versions, if: :saved_change_to_name?

  validate :aliases_are_not_other_skills
  validate :name_is_not_another_skills_alias
  validate :parent_is_one_level_deep
  validate :vendor_chosen_when_shown

  def self.find_by_name_or_alias(text)
    text = text.to_s.strip.downcase
    return if text.empty?

    find_by("LOWER(name) = :text OR :text = ANY (SELECT LOWER(a) FROM unnest(aliases) AS a)", text: text)
  end

  # Loads the vendor of each Skill that shows it in its name (display_name),
  # and only those, so nothing is loaded unused.
  def self.preload_vendors(skills)
    shown = skills.select(&:show_vendor_in_name)
    ActiveRecord::Associations::Preloader.new(records: shown, associations: :vendor).call if shown.any?
    skills
  end

  # An unsaved Skill for a name typed in a Tech Stack or Achievement, to be
  # filed properly later.
  def self.new_uncategorised(name)
    new(name: name, skill_category: Dossier::SkillCategory.find_or_create_by!(name: Dossier::TechStack::UNCATEGORISED))
  end

  # Folds a duplicate into target: Tech Stack, Achievement and Training links move
  # across (dropping any target already has), this Skill's name and aliases
  # become target's aliases, and this Skill is deleted.
  def merge_into!(target)
    raise ArgumentError, "A Skill can't be merged into itself" if target == self

    transaction do
      move_versions(target)
      move_links(assignment_skills, target, :assignment_id, :stack_slot)
      move_links(achievement_skills, target, :achievement_id)
      move_links(credential_skills, target, :credential_id)
      names = [ name, *aliases ]
      target.description ||= description
      target.assign_attributes(vendor: vendor, show_vendor_in_name: show_vendor_in_name) unless target.vendor
      destroy!
      target.update!(aliases: target.aliases + names)
    end
  end

  # The name readers see: "Microsoft Project" (the vendor's abbreviation, or
  # its name, first) when asked to show the vendor, otherwise just the name.
  def display_name
    return name unless show_vendor_in_name && vendor

    "#{vendor.abbreviation.presence || vendor.name} #{name}"
  end

  def to_toast_label = display_name

  # "Windows XP" for XP under Windows; just the name when it isn't a version
  # or already starts with its parent's (iOS 3 under iOS).
  def slug_name
    parent && version_label == name ? "#{parent.name} #{name}" : name
  end

  # Replaces the one NamedReferenceData defines on the class, so it repeats
  # its name check.
  def should_generate_new_friendly_id?
    name_changed? || parent_id_changed? || super
  end

  # The Skill a family is shown under: the parent, or itself.
  def family_root = parent || self

  # What sets a version apart: "XP" for Windows XP under Windows; the whole
  # name when it doesn't start with the parent's (Ubuntu under Linux).
  def version_label
    return name unless parent

    rest = name.sub(/\A#{Regexp.escape(parent.name)}\b/i, "").strip
    rest.empty? || rest == name ? name : rest
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

  # A merged Skill's versions become versions of the kept Skill (or of its
  # parent, when the kept Skill is itself a version).
  def move_versions(target)
    target.parent = nil if target.parent_id == id
    root = target.parent || target
    versions.where.not(id: target.id).find_each { |version| version.update!(parent: root) }
  end

  # The old slugs stay in the history, so old links still work.
  def reslug_versions
    versions.each { |version| version.update!(slug: nil) }
  end

  def parent_is_one_level_deep
    return unless parent

    if parent.equal?(self) || (persisted? && parent_id == id)
      errors.add(:parent, "can't be the Skill itself")
    elsif parent.parent_id
      errors.add(:parent, "is itself a version of #{parent.parent.name}")
    elsif persisted? && versions.exists?
      errors.add(:parent, "can't be set on a Skill that has versions")
    end
  end

  def vendor_chosen_when_shown
    errors.add(:vendor, "must be chosen to show it in the name") if show_vendor_in_name && vendor.nil?
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
