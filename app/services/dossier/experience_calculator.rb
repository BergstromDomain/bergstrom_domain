# app/services/dossier/experience_calculator.rb

# A user's experience from their kept Engagements: per Skill, career totals
# and slices by employer, employment type (Engagement dates), client,
# industry and role (Assignment dates). Years are always the union of dates (a
# current one runs to today), so overlaps never count twice. Personal
# Engagements' (hobby projects') time is counted apart and never adds to
# professional years or slices.
#
# An Assignment uses a Skill when it's in its Tech Stack or tagged on one of
# its kept Achievements — or one of the Skill's versions is (Windows XP counts
# for Windows too). Training (courses tagged with the Skill) is listed but
# never adds to years.
class Dossier::ExperienceCalculator
  # slots: Tech Stack slot (or :achievement) => Assignments, newest first.
  # months / personal_months: nil when the Skill has no professional / personal
  # Assignment. A Skill only learned on Training has no Assignments at all.
  SkillExperience = Data.define(:skill, :assignments, :slots, :achievements, :training, :months, :personal_months, :last_on) do
    def duration          = months && Dossier::Timeline.duration_of(months)
    def personal_duration = personal_months && Dossier::Timeline.duration_of(personal_months)
    def current?          = assignments.any? && last_on.nil?
    def first_on          = assignments.map(&:start_on).min

    def last_used
      return "—" if assignments.empty?

      current? ? "Present" : last_on.strftime("%b %Y")
    end
  end

  # One row of a slice: key is the record (nil for "No Role" / "No Industry").
  Slice = Data.define(:key, :label, :months, :first_on, :last_on, :assignment_count) do
    def duration = Dossier::Timeline.duration_of(months)

    def date_range
      from = first_on.strftime("%b %Y")
      to = last_on ? last_on.strftime("%b %Y") : "Present"
      from == to ? from : "#{from} – #{to}"
    end
  end

  # Career = union of Engagements (bench counts, gaps don't); assignment =
  # union of Assignments (no bench); personal = personal Engagements. nil
  # when there's nothing to count.
  Totals = Data.define(:career_months, :assignment_months, :personal_months) do
    def career         = format(career_months)
    def on_assignments = format(assignment_months)
    def personal       = format(personal_months)

    private

    def format(months) = months ? Dossier::Timeline.duration_of(months) : "—"
  end

  # How each slice finds its records: from an Engagement or an Assignment.
  ENGAGEMENT_SLICES = { employer: :employer, employment_type: :employment_type }.freeze
  ASSIGNMENT_SLICES = { client: :client, industry: ->(a) { a.client&.industry }, role: :role }.freeze
  NONE_LABELS = { industry: "No Industry", role: "No Role" }.freeze
  SLICE_PRELOADS = { client: :client, industry: { client: :industry }, role: :role }.freeze

  def initialize(user, today: Date.current)
    @user = user
    @today = today
  end

  # Most professional months first, then most personal months, then by name.
  def skills
    @skills ||= uses.map { |skill, use| build(skill, use) }
                    .sort_by { |e| [ -(e.months || -1), -(e.personal_months || -1), e.skill.name.downcase ] }
  end

  # Technical Skills (years, the CV's skills table) and Soft Skills, such as
  # Leadership, shown by their example Achievements instead.
  def technical_skills = categorised.fetch(false, [])
  def soft_skills      = categorised.fetch(true, [])

  def for_skill(skill)
    skills.find { |experience| experience.skill == skill }
  end

  def totals
    @totals ||= Totals.new(career_months: months(professional_engagements),
                           assignment_months: months(professional_engagements.flat_map(&:assignments)),
                           personal_months: months(engagements - professional_engagements))
  end

  # Rows for one slice (:employer, :employment_type, :client, :industry or
  # :role), most years first.
  def slice(name)
    (@slices ||= {})[name] ||= build_slice(name)
  end

  def experience_for(name, record) = slice(name).find { |row| row.key == record }

  private

  def categorised
    @categorised ||= begin
      soft = Dossier::SkillCategory.soft_ids.to_set
      skills.group_by { |experience| soft.include?(experience.skill.skill_category_id) }
    end
  end

  def engagements
    @engagements ||= @user.dossier_engagements.kept.includes(:employer, :employment_type, :assignments).to_a
  end

  def professional_engagements = @professional_engagements ||= engagements.reject(&:personal?)

  def build_slice(name)
    if (finder = ENGAGEMENT_SLICES[name])
      groups = professional_engagements.group_by(&finder)
      count = ->(list) { list.sum { |engagement| engagement.assignments.size } }
    elsif (finder = ASSIGNMENT_SLICES[name])
      assignments = professional_engagements.flat_map(&:assignments)
      # Each slice loads only what it reads (the Organisation page needs no Roles).
      ActiveRecord::Associations::Preloader.new(records: assignments, associations: SLICE_PRELOADS.fetch(name)).call
      groups = assignments.group_by(&finder)
      count = :size.to_proc
    else
      raise ArgumentError, "Unknown slice #{name.inspect}"
    end

    groups.map { |key, list| slice_row(name, key, list, count.(list)) }
          .sort_by { |row| [ -row.months, row.label.downcase ] }
  end

  def slice_row(name, key, dated, assignment_count)
    Slice.new(key: key, label: key&.to_toast_label || NONE_LABELS.fetch(name), months: months(dated),
              first_on: dated.map(&:start_on).min,
              last_on: dated.any?(&:current?) ? nil : dated.map(&:effective_end).max,
              assignment_count: assignment_count)
  end

  def assignments
    Dossier::Assignment.kept.where(engagement_id: @user.dossier_engagements.kept.select(:id))
                       .includes(engagement: :employment_type, assignment_skills: { skill: :parent },
                                 achievements: { achievement_skills: { skill: :parent } })
  end

  def training
    @user.dossier_credentials.training.kept.started.newest_first.includes(credential_skills: { skill: :parent })
  end

  def uses
    found = assignments.each_with_object({}) do |assignment, uses|
      assignment.assignment_skills.each do |link|
        family(link.skill).each { |skill| add(uses, skill, assignment, link.stack_slot&.to_sym || :other) }
      end
      assignment.achievements.each do |achievement|
        achievement.achievement_skills.each do |link|
          family(link.skill).each do |skill|
            use = add(uses, skill, assignment, :achievement)
            use[:achievements] << achievement unless use[:achievements].include?(achievement)
          end
        end
      end
    end
    training.each do |credential|
      credential.credential_skills.each do |link|
        family(link.skill).each do |skill|
          list = use_for(found, skill)[:training]
          list << credential unless list.include?(credential)
        end
      end
    end
    found
  end

  # A version (Windows XP) counts for itself and for its Skill (Windows).
  def family(skill) = [ skill, skill.parent ].compact

  def add(uses, skill, assignment, slot)
    use = use_for(uses, skill)
    use[:slots][slot] << assignment unless use[:slots][slot].include?(assignment)
    use
  end

  def use_for(uses, skill)
    uses[skill] ||= { slots: Hash.new { |hash, key| hash[key] = [] }, achievements: [], training: [] }
  end

  def build(skill, use)
    assignments = use[:slots].values.flatten.uniq
    # A Tech Stack listing makes :achievement redundant for the same Assignment.
    tech_stack = use[:slots].except(:achievement).values.flatten
    slots = use[:slots].to_h { |slot, list| [ slot, slot == :achievement ? list - tech_stack : list ] }
                       .reject { |_, list| list.empty? }
                       .transform_values { |list| newest_first(list) }

    personal, professional = assignments.partition { |a| a.engagement.personal? }
    last_on = assignments.any?(&:current?) ? nil : assignments.map(&:effective_end).compact.max

    SkillExperience.new(skill: skill, assignments: newest_first(assignments), slots: slots,
                        achievements: use[:achievements], training: use[:training], months: months(professional),
                        personal_months: months(personal), last_on: last_on)
  end

  # Union of the dated records' (Engagements' or Assignments') ranges.
  def months(dated)
    return if dated.empty?

    periods = dated.map { |a| Dossier::Timeline::Period.new(from: a.start_on, to: a.effective_end || @today) }
    Dossier::Timeline.months(Dossier::Timeline.merge(periods).sum { |period| period.to - period.from + 1 })
  end

  def newest_first(assignments)
    assignments.sort_by { |a| [ a.effective_end || @today, a.start_on ] }.reverse
  end
end
