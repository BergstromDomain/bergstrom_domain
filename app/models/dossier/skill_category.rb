# app/models/dossier/skill_category.rb

# Groups Skills. A category can sit under a top-level one as a sub-category
# (VoIP under Protocols & Standards), one level deep; names are unique within
# their parent, so "Other" can exist under several parents.
class Dossier::SkillCategory < ApplicationRecord
  include Dossier::NamedReferenceData

  # A sub-category's slug is its name, or "<parent>-<name>" when that's taken.
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  belongs_to :parent, class_name: "Dossier::SkillCategory", optional: true
  has_many :subcategories, -> { order(Arel.sql("LOWER(name)")) }, class_name: "Dossier::SkillCategory",
                                                                 foreign_key: :parent_id, inverse_of: :parent,
                                                                 dependent: :restrict_with_error
  has_many :skills, dependent: :restrict_with_error

  validates :name, uniqueness: { case_sensitive: false, scope: :parent_id }
  validate :parent_is_one_level_deep

  scope :top_level, -> { where(parent_id: nil) }

  # Each top-level category A–Z, followed by its sub-categories A–Z.
  def self.in_tree_order
    all.includes(:parent).sort_by { |category| category.tree_sort_key }
  end

  def top_level? = parent_id.nil?

  # "Protocols & Standards › VoIP", or just the name at the top level.
  def full_name = parent ? "#{parent.name} › #{name}" : name

  def to_toast_label = full_name

  # Its own Skills and every sub-category's.
  def all_skills
    Dossier::Skill.where(skill_category_id: [ id, *subcategories.ids ])
  end

  def tree_sort_key
    parent ? [ parent.name.downcase, 1, name.downcase ] : [ name.downcase, 0, "" ]
  end

  def name_unique_within_scope? = true

  private

  def slug_candidates = [ :name, [ :parent_name, :name ] ]

  def parent_name = parent&.name

  def parent_is_one_level_deep
    return unless parent

    if parent == self
      errors.add(:parent, "can't be itself")
    elsif parent.parent_id
      errors.add(:parent, "must be a top-level Skill Category")
    elsif persisted? && subcategories.exists?
      errors.add(:parent, "can't be set while it has sub-categories")
    end
  end
end
