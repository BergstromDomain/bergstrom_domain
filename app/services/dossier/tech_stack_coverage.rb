# app/services/dossier/tech_stack_coverage.rb

# Keeps an Assignment's Tech Stack and its Achievements in step.
#
# add! puts Tech Skills (an Achievement's) in the Stack: each in the list
# for its category (TechStack.slot_for, or System Under Test for that
# category), clearing the list's N/A. A Skill whose family is already
# anywhere in the Stack isn't added: "Windows 10" isn't, with "Windows" there.
# Soft Skills never go in.
#
# uncovered lists the Stack Skills no kept Achievement names (a Skill's
# family counts), in Stack order, for the Assignment's save warning. Not
# asked for: System Under Test Skills (wherever else they're listed), and
# Skills in the EXEMPT categories, as nobody writes Achievements about Teams.
class Dossier::TechStackCoverage
  EXEMPT_CATEGORIES = [ "Office & Collaboration", "Operating Systems" ].freeze
  SYSTEM_UNDER_TEST = "System Under Test"

  # One-off, for Achievements written before add! ran on save: each of the
  # user's kept Assignments gets its kept Achievements' Tech Skills. Returns
  # "Heading: Skill, Skill" per Assignment changed (or that would be).
  def self.backfill(user, dry_run: false)
    assignments = Dossier::Assignment.kept.where(user_id: user.id).order(:start_on, :id)
                                     .includes(:client, assignment_skills: :skill, achievements: { achievement_skills: :skill })
    assignments.filter_map do |assignment|
      skills = assignment.achievements.flat_map(&:technical_skills)
      added = new(assignment).add!(skills, dry_run: dry_run)
      "#{assignment.heading}: #{added.map(&:display_name).join(', ')}" if added.any?
    end
  end

  def initialize(assignment)
    @assignment = assignment
  end

  # The Skills added (or that would be, on a dry run).
  def add!(skills, dry_run: false)
    present = families(links.map(&:skill))
    candidates = skills.uniq.reject { |skill| present.include?(skill.family_root) }
    preload_categories(candidates)
    added = candidates.reject { |skill| soft?(skill) }
    return added if dry_run || added.empty?

    added.each do |skill|
      slot = slot_for(skill)
      @assignment.assignment_skills.build(skill: skill, stack_slot: slot.to_s)
      @assignment[:"#{Dossier::TechStack::SLOTS.fetch(slot)}_na"] = false
    end
    @assignment.save ? added : []
  end

  def uncovered
    named = @assignment.achievements.includes(achievement_skills: { skill: :parent })
                       .flat_map { |achievement| achievement.current_skills.map(&:family_root) }
    under_test = stack_links.select { |link| link.stack_slot == "system_under_test" }.map { |link| link.skill.family_root }
    candidates = stack_links.map(&:skill).uniq.reject do |skill|
      under_test.include?(skill.family_root) || named.include?(skill.family_root)
    end
    preload_categories(candidates)
    candidates.reject { |skill| exempt?(skill) }
  end

  private

  def links
    preload([ @assignment ], { assignment_skills: :skill }) unless @assignment.association(:assignment_skills).loaded?
    @assignment.assignment_skills.reject(&:marked_for_destruction?)
  end

  # The Stack's links, in Stack order (SLOTS, then as entered).
  def stack_links
    @stack_links ||= begin
      slots = Dossier::TechStack::SLOTS.keys.map(&:to_s)
      sorted = links.sort_by { |link| [ slots.index(link.stack_slot) || slots.size, link.id.to_i ] }
      families(sorted.map(&:skill))
      sorted
    end
  end

  # The Skills' families, their parents loaded at once (only what's read is
  # loaded, which Bullet checks).
  def families(skills)
    preload(skills.select { |skill| skill.persisted? && !skill.association(:parent).loaded? }, :parent)
    skills.map(&:family_root)
  end

  # What top_category reads, for these Skills' families.
  def preload_categories(skills)
    roots = families(skills).uniq
    preload(roots.reject { |root| root.association(:skill_category).loaded? }, :skill_category)
    categories = roots.map(&:skill_category).uniq
    preload(categories.reject { |category| category.association(:parent).loaded? }, :parent)
  end

  def preload(records, association)
    ActiveRecord::Associations::Preloader.new(records: records, associations: association).call if records.any?
  end

  def top_category(skill) = Dossier::TechStack.top_category(skill)

  def soft?(skill) = top_category(skill).soft?

  def exempt?(skill) = EXEMPT_CATEGORIES.include?(top_category(skill).name)

  def slot_for(skill)
    top_category(skill).name == SYSTEM_UNDER_TEST ? :system_under_test : Dossier::TechStack.slot_for(skill)
  end
end
