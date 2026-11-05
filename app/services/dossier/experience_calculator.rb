# app/services/dossier/experience_calculator.rb

# A user's experience per Skill, from their kept Engagements' Assignments. An
# Assignment uses a Skill when it's in its Tech Stack or tagged on one of its
# kept Achievements. Years are the union of those Assignments' dates (a
# current one runs to today), so overlaps never count twice. Personal
# Engagements' (hobby projects') time is counted apart and never adds to
# professional years. Training (courses tagged with the Skill) is listed but
# never adds to years. Block 6 adds slices by employer, client and industry.
class Dossier::ExperienceCalculator
  # slots: Tech Stack slot (or :achievement) => Assignments, newest first.
  # months / personal_months: nil when the Skill has no professional / personal
  # Assignment. A Skill only learned on Training has no Assignments at all.
  SkillExperience = Data.define(:skill, :assignments, :slots, :achievements, :training, :months, :personal_months, :last_on) do
    def duration          = months && Dossier::Timeline.duration_of(months)
    def personal_duration = personal_months && Dossier::Timeline.duration_of(personal_months)
    def current?          = assignments.any? && last_on.nil?

    def last_used
      return "—" if assignments.empty?

      current? ? "Present" : last_on.strftime("%b %Y")
    end
  end

  def initialize(user, today: Date.current)
    @user = user
    @today = today
  end

  # Most professional months first, then most personal months, then by name.
  def skills
    @skills ||= uses.map { |skill, use| build(skill, use) }
                    .sort_by { |e| [ -(e.months || -1), -(e.personal_months || -1), e.skill.name.downcase ] }
  end

  def for_skill(skill)
    skills.find { |experience| experience.skill == skill }
  end

  private

  def assignments
    Dossier::Assignment.where(engagement_id: @user.dossier_engagements.kept.select(:id))
                       .includes(engagement: :employment_type, assignment_skills: :skill,
                                 achievements: { achievement_skills: :skill })
  end

  def training
    @user.dossier_credentials.training.kept.newest_first.includes(credential_skills: :skill)
  end

  def uses
    found = assignments.each_with_object({}) do |assignment, uses|
      assignment.assignment_skills.each do |link|
        add(uses, link.skill, assignment, link.stack_slot&.to_sym || :other)
      end
      assignment.achievements.each do |achievement|
        achievement.achievement_skills.each do |link|
          use = add(uses, link.skill, assignment, :achievement)
          use[:achievements] << achievement
        end
      end
    end
    training.each do |credential|
      credential.credential_skills.each { |link| use_for(found, link.skill)[:training] << credential }
    end
    found
  end

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

  def months(assignments)
    return if assignments.empty?

    periods = assignments.map { |a| Dossier::Timeline::Period.new(from: a.start_on, to: a.effective_end || @today) }
    Dossier::Timeline.months(Dossier::Timeline.merge(periods).sum { |period| period.to - period.from + 1 })
  end

  def newest_first(assignments)
    assignments.sort_by { |a| [ a.effective_end || @today, a.start_on ] }.reverse
  end
end
