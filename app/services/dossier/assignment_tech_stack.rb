# app/services/dossier/assignment_tech_stack.rb

# An Assignment's Tech Stack as its page shows it: the System Under Test on its
# own (in the order entered), and every other Skill in a block per top-level Skill Category (in
# position order). A block's columns: the Skills filed under the category
# itself (no heading), when there are any, then a column per sub-category
# that has Skills. A Skill's
# versions show with it as one family ("Windows (XP, 7)"), filed under the
# parent's category; a Skill on several lists shows once.
class Dossier::AssignmentTechStack
  Family = Data.define(:root, :versions)
  Column = Data.define(:heading, :families)
  Block  = Data.define(:category, :columns)

  def initialize(assignment)
    @assignment = assignment
  end

  def systems_under_test
    families(@assignment.skills_in(:system_under_test), by_category: false)
  end

  def blocks
    skills = (Dossier::TechStack::SLOTS.keys - [ :system_under_test ]).flat_map { |slot| @assignment.skills_in(slot) }
    by_top = families(skills, by_category: true).group_by { |family| top_of(family.root.skill_category) }
    by_top.sort_by { |top, _| top.display_sort_key }.map { |top, list| block(top, list) }
  end

  private

  def block(top, families)
    by_category = families.group_by { |family| family.root.skill_category }
    own = by_category.delete(top)
    subcategories = by_category.keys.sort_by(&:display_sort_key)
    Block.new(category: top,
              columns: [ (Column.new(heading: nil, families: own) if own),
                         *subcategories.map { |sub| Column.new(heading: sub.name, families: by_category.fetch(sub)) } ].compact)
  end

  def top_of(category) = category.parent || category

  # Loads only what the page reads (each Skill's parent; when grouping,
  # each family's category and its parent; a vendor shown in a name), so
  # nothing is loaded one Skill at a time and nothing is loaded unused.
  def preload_for_display(skills, by_category:)
    preload(skills, :parent)
    roots = skills.map(&:family_root).uniq
    preload(roots, skill_category: :parent) if by_category
    Dossier::Skill.preload_vendors((roots + skills).uniq)
    skills
  end

  def preload(records, associations)
    ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call if records.any?
  end

  # In the order entered for the System Under Test (the main system first),
  # A–Z for the tables.
  def families(skills, by_category:)
    skills = preload_for_display(skills.uniq, by_category: by_category)
    list = skills.group_by(&:family_root)
                 .map { |root, members| Family.new(root: root, versions: (members - [ root ]).sort_by { |s| s.name.downcase }) }
    by_category ? list.sort_by { |family| family.root.display_name.downcase } : list
  end
end
