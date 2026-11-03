# app/services/dossier/experience_calculator.rb

# A user's experience per Skill, from their kept Engagements' Assignments. An
# Assignment uses a Skill when it's in its Tech Stack or tagged on one of its
# kept Achievements. Years are the union of those Assignments' dates (a
# current one runs to today), so overlaps never count twice. Block 6 adds
# slices by employer, client and industry.
class Dossier::ExperienceCalculator
  # slots: Tech Stack slot (or :achievement) => Assignments, newest first.
  SkillExperience = Data.define(:skill, :assignments, :slots, :achievements, :months, :last_on) do
    def duration  = Dossier::Timeline.duration_of(months)
    def current?  = last_on.nil?
    def last_used = current? ? "Present" : last_on.strftime("%b %Y")
  end

  def initialize(user, today: Date.current)
    @user = user
    @today = today
  end

  # Most months first, then by name.
  def skills
    @skills ||= uses.map { |skill, use| build(skill, use) }
                    .sort_by { |experience| [ -experience.months, experience.skill.name.downcase ] }
  end

  def for_skill(skill)
    skills.find { |experience| experience.skill == skill }
  end

  private

  def assignments
    Dossier::Assignment.where(engagement_id: @user.dossier_engagements.kept.select(:id))
                       .includes(assignment_skills: :skill, achievements: { achievement_skills: :skill })
  end

  def uses
    assignments.each_with_object({}) do |assignment, uses|
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
  end

  def add(uses, skill, assignment, slot)
    use = uses[skill] ||= { slots: Hash.new { |hash, key| hash[key] = [] }, achievements: [] }
    use[:slots][slot] << assignment unless use[:slots][slot].include?(assignment)
    use
  end

  def build(skill, use)
    assignments = use[:slots].values.flatten.uniq
    # A Tech Stack listing makes :achievement redundant for the same Assignment.
    tech_stack = use[:slots].except(:achievement).values.flatten
    slots = use[:slots].to_h { |slot, list| [ slot, slot == :achievement ? list - tech_stack : list ] }
                       .reject { |_, list| list.empty? }
                       .transform_values { |list| newest_first(list) }

    periods = assignments.map { |a| Dossier::Timeline::Period.new(from: a.start_on, to: a.effective_end || @today) }
    days = Dossier::Timeline.merge(periods).sum { |period| period.to - period.from + 1 }
    last_on = assignments.any?(&:current?) ? nil : assignments.map(&:effective_end).max

    SkillExperience.new(skill: skill, assignments: newest_first(assignments), slots: slots,
                        achievements: use[:achievements], months: Dossier::Timeline.months(days), last_on: last_on)
  end

  def newest_first(assignments)
    assignments.sort_by { |a| [ a.effective_end || @today, a.start_on ] }.reverse
  end
end
