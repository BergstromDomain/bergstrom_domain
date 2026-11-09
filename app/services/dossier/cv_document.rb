# app/services/dossier/cv_document.rb

# The master CV's content, in order, with no formatting: what both the PDF
# (HTML) and the Word renderers lay out. Header and summary come from the
# Profile; Experience and Personal Projects from kept Engagements, newest
# first, each with its Assignments, Tech Stack and kept Achievements; Skills
# grouped by Skill Category; Credentials grouped by Credential Type in type
# order, with all training types together as "Training". A permanent job's
# single synced Assignment folds into its Engagement (heading, role and dates
# nil), so the CV doesn't repeat them.
#
# With a CV Variant, only what its Dossier::CvSelection shows is kept: a
# condensed Engagement has no summary or Assignments, the Tech Stack shows
# only if the variant asks, and the summary is the variant's.
class Dossier::CvDocument
  Header     = Data.define(:name, :headline, :contacts)
  Job        = Data.define(:title, :organisation, :employment_type, :dates, :summary, :assignments)
  Assignment = Data.define(:heading, :role, :dates, :location, :summary, :tech_stack, :achievements)
  Section    = Data.define(:heading, :entries)
  Credential = Data.define(:title, :provider, :dates, :expired)

  TRAINING_HEADING = "Training"

  def initialize(user, today: Date.current, variant: nil)
    @user = user
    @today = today
    @profile = user.dossier_profile
    @variant = variant
    @selection = variant && Dossier::CvSelection.new(variant, today: today)
  end

  def profile? = @profile.present?

  def header
    contacts = [ @profile.location&.name, @profile.email, @profile.phone,
                 @profile.website_url, @profile.linkedin_url, @profile.github_url ].compact
    Header.new(name: @profile.display_name, headline: @profile.headline, contacts: contacts)
  end

  def summary = @variant ? @variant.summary : @profile.summary_for(:first_person)

  def experience        = jobs.reject(&:first).map(&:last)
  def personal_projects = jobs.select(&:first).map(&:last)

  # [[top-level category name, line], …], categories A–Z. The line lists the
  # category's own Skills, most years first, then each sub-category's A–Z:
  # "TCP/IP; VoIP: SIP, MGCP". A Skill's versions show as one family:
  # "Windows (XP, Vista)".
  def skills
    experiences = experience_calculator.skills
    experiences = experiences.select { |experience| @selection.included?(experience.skill) } if @selection
    families = experiences.map(&:skill).group_by(&:family_root)
    ActiveRecord::Associations::Preloader.new(records: families.keys, associations: { skill_category: :parent }).call
    families.group_by { |root, _| root.skill_category.parent || root.skill_category }
            .sort_by { |category, _| category.name.downcase }
            .map { |category, list| [ category.name, skill_line(category, list) ] }
  end

  def credentials
    shown = @user.dossier_credentials.kept.includes(:credential_type).newest_first.select { |credential| shown?(credential) }
    # Providers only for those shown, so a variant's left-out Training loads none.
    ActiveRecord::Associations::Preloader.new(records: shown, associations: :provider).call
    shown.group_by { |credential| credential.training? ? TRAINING_HEADING : credential.credential_type }
         .sort_by { |key, list| [ list.map { |c| c.credential_type.position }.min, key == TRAINING_HEADING ? 1 : 0 ] }
         .map do |key, list|
           heading = key == TRAINING_HEADING ? key : key.name.pluralize
           Section.new(heading: heading, entries: list.map { |credential| credential_entry(credential) })
         end
  end

  # "Alex_Example_CV_2026-11-05.pdf", or with a variant
  # "Alex_Example_CV_QE_Lead_Acme_2026-11-05.pdf".
  def filename(extension)
    parts = [ @profile.display_name, "CV", @variant&.name ].compact.map { |part| safe_filename(part) }
    "#{parts.join('_')}_#{@today.iso8601}.#{extension}"
  end

  private

  # [[personal?, Job], …], newest first.
  def jobs
    @jobs ||= @user.dossier_engagements.kept.newest_first
                   .includes(:employer, :employment_type,
                             assignments: [ :client, :role, :location, :achievements, { assignment_skills: { skill: :parent } } ])
                   .select { |engagement| shown?(engagement) }
                   .map { |engagement| [ engagement.personal?, job(engagement) ] }
  end

  def job(engagement)
    assignments = engagement.assignments.select { |assignment| shown?(assignment) }
                            .sort_by { |a| [ a.effective_end || @today, a.start_on ] }.reverse
    condensed = assignments.empty? && @selection
    Job.new(title: engagement.position_title, organisation: engagement.employer.name,
            employment_type: engagement.employment_type.name, dates: engagement.date_range,
            summary: (engagement.summary unless condensed),
            assignments: assignments.map { |assignment| assignment_entry(assignment, folded: folded?(engagement)) })
  end

  # One Assignment for the Engagement's own employer and dates: nothing to add.
  def folded?(engagement)
    return false unless engagement.assignments.size == 1

    only = engagement.assignments.first
    only.client_id == engagement.employer_id && only.date_range == engagement.date_range && only.project.nil? &&
      (only.role.nil? || only.role.name == engagement.position_title)
  end

  def assignment_entry(assignment, folded:)
    Assignment.new(heading: (assignment.heading unless folded),
                   role: (assignment.role_name unless folded),
                   dates: (assignment.date_range unless folded),
                   location: location(assignment),
                   summary: assignment.summary,
                   tech_stack: (@variant && !@variant.show_tech_stack ? [] : tech_stack(assignment)),
                   achievements: assignment.achievements.select { |a| shown?(a) }.map { |a| [ a.text, a.impact ].compact.join(" — ") })
  end

  # Everything, for the master CV; a variant's selection otherwise.
  def shown?(record) = @selection.nil? || @selection.shown?(record)

  def safe_filename(text) = text.gsub(/[^\p{Alnum}]+/, "_").delete_prefix("_").delete_suffix("_")

  def location(assignment)
    return "Remote" if assignment.remote && assignment.location.nil?
    return unless assignment.location

    assignment.remote ? "#{assignment.location.name} (Remote)" : assignment.location.name
  end

  # [["Test Tools", "Jira, qTest"], …], N/A lists left out; versions as
  # families, like Skills.
  def tech_stack(assignment)
    Dossier::TechStack::SLOTS.filter_map do |slot, plural|
      families = assignment.skills_in(slot).group_by(&:family_root)
      names = families.map { |root, members| family_name(root, members) }
      [ Dossier::TechStack::LABELS.fetch(plural), names.join(", ") ] if names.any?
    end
  end

  def experience_calculator
    @experience_calculator ||= Dossier::ExperienceCalculator.new(@user, today: @today)
  end

  # "Windows" alone, or "Windows (XP, Vista)" with its versions in the order
  # first used.
  def family_name(root, members)
    versions = members.reject { |skill| skill == root }
    return root.display_name if versions.empty?

    first_used = ->(skill) { experience_calculator.for_skill(skill)&.first_on || Date.new(9999) }
    labels = versions.sort_by { |skill| [ first_used.(skill), skill.name.downcase ] }.map(&:version_label)
    "#{root.display_name} (#{labels.join(', ')})"
  end

  def skill_line(category, families)
    by_category = families.group_by { |root, _| root.skill_category }
    own = by_category.delete(category)
    subcategories = by_category.sort_by { |subcategory, _| subcategory.name.downcase }
                               .map { |subcategory, list| "#{subcategory.name}: #{family_names(list)}" }
    [ (family_names(own) if own), *subcategories ].compact.join("; ")
  end

  def family_names(families) = families.map { |root, members| family_name(root, members) }.join(", ")

  def credential_entry(credential)
    Credential.new(title: credential.title, provider: credential.provider&.name,
                   dates: credential.dates, expired: credential.expired?(@today))
  end
end
