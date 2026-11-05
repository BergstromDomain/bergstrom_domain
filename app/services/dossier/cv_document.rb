# app/services/dossier/cv_document.rb

# The master CV's content, in order, with no formatting: what both the PDF
# (HTML) and the Word renderers lay out. Header and summary come from the
# Profile; Experience and Personal Projects from kept Engagements, newest
# first, each with its Assignments, Tech Stack and kept Achievements; Skills
# grouped by Skill Category; Credentials grouped by Credential Type in type
# order, with all training types together as "Training". A permanent job's
# single synced Assignment folds into its Engagement (heading, role and dates
# nil), so the CV doesn't repeat them.
class Dossier::CvDocument
  Header     = Data.define(:name, :headline, :contacts)
  Job        = Data.define(:title, :organisation, :employment_type, :dates, :summary, :assignments)
  Assignment = Data.define(:heading, :role, :dates, :location, :summary, :tech_stack, :achievements)
  Section    = Data.define(:heading, :entries)
  Credential = Data.define(:title, :provider, :dates, :expired)

  TRAINING_HEADING = "Training"

  def initialize(user, today: Date.current)
    @user = user
    @today = today
    @profile = user.dossier_profile
  end

  def profile? = @profile.present?

  def header
    contacts = [ @profile.location&.name, @profile.email, @profile.phone,
                 @profile.website_url, @profile.linkedin_url, @profile.github_url ].compact
    Header.new(name: @profile.display_name, headline: @profile.headline, contacts: contacts)
  end

  def summary = @profile.summary_for(:first_person)

  def experience        = jobs.reject(&:first).map(&:last)
  def personal_projects = jobs.select(&:first).map(&:last)

  # [[category name, [skill names, most years first]], …], categories A–Z.
  def skills
    experiences = Dossier::ExperienceCalculator.new(@user, today: @today).skills
    ActiveRecord::Associations::Preloader.new(records: experiences.map(&:skill), associations: :skill_category).call
    experiences.group_by { |experience| experience.skill.skill_category.name }
               .sort_by { |category, _| category.downcase }
               .map { |category, list| [ category, list.map { |experience| experience.skill.name } ] }
  end

  def credentials
    @user.dossier_credentials.kept.includes(:credential_type, :provider).newest_first.to_a
         .group_by { |credential| credential.training? ? TRAINING_HEADING : credential.credential_type }
         .sort_by { |key, list| [ list.map { |c| c.credential_type.position }.min, key == TRAINING_HEADING ? 1 : 0 ] }
         .map do |key, list|
           heading = key == TRAINING_HEADING ? key : key.name.pluralize
           Section.new(heading: heading, entries: list.map { |credential| credential_entry(credential) })
         end
  end

  # "Alex_Example_CV_2026-11-05.pdf"
  def filename(extension)
    name = @profile.display_name.gsub(/[^\p{Alnum}]+/, "_").delete_prefix("_").delete_suffix("_")
    "#{name}_CV_#{@today.iso8601}.#{extension}"
  end

  private

  # [[personal?, Job], …], newest first.
  def jobs
    @jobs ||= @user.dossier_engagements.kept.newest_first
                   .includes(:employer, :employment_type,
                             assignments: [ :client, :role, :location, :achievements, { assignment_skills: :skill } ])
                   .map { |engagement| [ engagement.personal?, job(engagement) ] }
  end

  def job(engagement)
    assignments = engagement.assignments.sort_by { |a| [ a.effective_end || @today, a.start_on ] }.reverse
    Job.new(title: engagement.position_title, organisation: engagement.employer.name,
            employment_type: engagement.employment_type.name, dates: engagement.date_range,
            summary: engagement.summary,
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
                   tech_stack: tech_stack(assignment),
                   achievements: assignment.achievements.map { |a| [ a.text, a.impact ].compact.join(" — ") })
  end

  def location(assignment)
    return "Remote" if assignment.remote && assignment.location.nil?
    return unless assignment.location

    assignment.remote ? "#{assignment.location.name} (Remote)" : assignment.location.name
  end

  # [["Test Tools", "Jira, qTest"], …], N/A lists left out.
  def tech_stack(assignment)
    Dossier::TechStack::SLOTS.filter_map do |slot, plural|
      names = assignment.skills_in(slot).map(&:name)
      [ Dossier::TechStack::LABELS.fetch(plural), names.join(", ") ] if names.any?
    end
  end

  def credential_entry(credential)
    Credential.new(title: credential.title, provider: credential.provider&.name,
                   dates: credential.dates, expired: credential.expired?(@today))
  end
end
