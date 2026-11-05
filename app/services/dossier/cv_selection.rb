# app/services/dossier/cv_selection.rb

# What a CV Variant includes. An explicit item row (ticked or unticked)
# always wins; otherwise the default rules:
# * Engagements: all but Personal Projects. Those ending in the last
#   DETAIL_PERIOD are shown in full; older ones are condensed (no Assignments)
#   unless one of their Assignments is ticked.
# * Assignments: those of Engagements ending in the last DETAIL_PERIOD.
# * Achievements: importance at least the variant's min_importance.
# * Skills: those with professional years, except the Uncategorised category.
# * Credentials: all but Training and expired ones.
# included? is the record's own tick; shown? also needs its parents shown
# (an Achievement under a left-out Assignment isn't on the CV).
class Dossier::CvSelection
  DETAIL_PERIOD = 10.years

  def initialize(variant, today: Date.current)
    @variant = variant
    @today = today
  end

  def included?(record)
    explicit.fetch([ record.class.name, record.id ]) { default?(record) }
  end

  def default?(record)
    case record
    when Dossier::Engagement  then !record.personal?
    when Dossier::Assignment  then recent?(record.engagement)
    when Dossier::Achievement then record.importance >= @variant.min_importance
    when Dossier::Skill       then professional_skill_ids.include?(record.id)
    when Dossier::Credential  then !record.training? && !record.expired?(@today)
    else raise ArgumentError, "No CV rule for #{record.class.name}"
    end
  end

  def shown?(record)
    return false unless included?(record)

    case record
    when Dossier::Assignment  then shown?(record.engagement)
    when Dossier::Achievement then shown?(record.assignment)
    else true
    end
  end

  # Shown as title, employer and dates only.
  def condensed?(engagement)
    engagement.assignments.none? { |assignment| included?(assignment) }
  end

  private

  def explicit
    @explicit ||= @variant.items.to_h { |item| [ [ item.item_type, item.item_id ], item.included ] }
  end

  def recent?(engagement)
    engagement.current? || engagement.effective_end >= @today - DETAIL_PERIOD
  end

  def professional_skill_ids
    @professional_skill_ids ||= begin
      experiences = Dossier::ExperienceCalculator.new(@variant.user, today: @today).skills.select(&:months)
      ActiveRecord::Associations::Preloader.new(records: experiences.map(&:skill), associations: :skill_category).call
      experiences.reject { |e| e.skill.skill_category.name == Dossier::TechStack::UNCATEGORISED }.map { |e| e.skill.id }.to_set
    end
  end
end
