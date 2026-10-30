# app/services/dossier/import.rb

# Imports a Bridge CV master list (master_cv.yaml) into the user's Dossier:
# Profile, Organisations, Skills, then Engagements › Assignments with their
# Tech Stack. Fields that aren't CV data (vendors, notes, src, linkedin…) are
# never read. A record that already exists is skipped, never updated, so a
# re-import keeps edits made in the app.
#
# All or nothing: #preview runs the whole import and rolls it back, so the
# preview and #import! can't disagree; any error rolls #import! back too.
# Admin-only reference data (Employment Types, Roles, Industries, Locations,
# Skill Categories) is created only for an Admin — anyone else gets an error
# (required) or a warning (optional) instead.
class Dossier::Import
  Result = Struct.new(:created, :existing, :warnings, :errors, keyword_init: true) do
    def ok? = errors.empty?
  end

  SECTIONS = %w[profile organisations skills engagements].freeze
  NA = "N/A"

  # The master list tags items with their source CV: "Provar (D)", "Test Tools (P tools)".
  SOURCE_TAG = /\s*\([A-Z](?: [a-z]+)?\)\z/

  def initialize(user, text)
    @user = user
    @text = text
  end

  def preview = run(commit: false)
  def import! = run(commit: true)

  private

  def run(commit:)
    @created, @existing, @warnings, @errors = {}, {}, [], []
    @created_keys = Set.new
    @skill_categories = {}

    if (data = parse)
      # requires_new: a plain nested transaction ignores ActiveRecord::Rollback.
      ActiveRecord::Base.transaction(requires_new: true) do
        import_all(data)
        raise ActiveRecord::Rollback unless commit && @errors.empty?
      end
    end

    Result.new(created: @created, existing: @existing.transform_values(&:uniq), warnings: @warnings, errors: @errors)
  end

  def parse
    data = YAML.safe_load(@text.to_s, permitted_classes: [ Date ], aliases: true)
    return data if data.is_a?(Hash) && data.keys.intersect?(SECTIONS)

    @errors << "Not a master list: expected profile, organisations, skills or engagements"
    nil
  rescue Psych::Exception => e
    @errors << "Not a valid YAML file: #{e.message}"
    nil
  end

  def import_all(data)
    import_profile(data["profile"]) if data["profile"]
    Array(data["organisations"]).each { |row| import_organisation(row) }
    import_skills(data["skills"] || {})
    Array(data["engagements"]).each { |row| import_engagement(row) }
  end

  # ── Organisations ────────────────────────────────────────────────────────

  def import_organisation(row)
    name = row["name"].to_s.strip
    if (organisation = find_named(Dossier::Organisation, name))
      return note_existing("Organisation", organisation.name, organisation)
    end

    save(Dossier::Organisation.new(
      name: name, abbreviation: row["abbreviation"], description: row["description"],
      industry: reference(Dossier::Industry, row["industry"], on: "Organisation #{name}")
    ), "Organisation", name)
  end

  # An employer or client named on an Engagement or Assignment.
  def organisation(name)
    name = name.to_s.strip
    return if name.empty?

    find_named(Dossier::Organisation, name) || save(Dossier::Organisation.new(name: name), "Organisation", name)
  end

  # ── Skills ───────────────────────────────────────────────────────────────

  # A Skill listed under two categories keeps the first.
  def import_skills(skills)
    skills.each do |category_name, names|
      Array(names).each do |raw|
        name = untag(raw)
        next if name.empty?

        if (skill = Dossier::Skill.find_by_name_or_alias(name))
          note_existing("Skill", skill.name, skill)
        else
          save(Dossier::Skill.new(name: name, skill_category: skill_category(untag(category_name))), "Skill", name)
        end
      end
    end
  end

  def skill_category(name)
    @skill_categories[name.downcase] ||=
      find_named(Dossier::SkillCategory, name) ||
      (admin? ? save(Dossier::SkillCategory.new(name: name), "Skill Category", name) : uncategorised(name))
  end

  def uncategorised(name)
    @warnings << "Skill Category '#{name}' is unknown — its Skills go in #{Dossier::TechStack::UNCATEGORISED}"
    Dossier::SkillCategory.find_or_create_by!(name: Dossier::TechStack::UNCATEGORISED)
  end

  # ── Profile ──────────────────────────────────────────────────────────────

  # terse_summary is the summary; the first summary per voice gives the
  # first- and third-person versions.
  def import_profile(row)
    if (profile = Dossier::Profile.find_by(user_id: @user.id))
      return note_existing("Profile", profile.display_name, profile)
    end

    name = row["name"].to_s.strip
    summaries = Array(row["summaries"])
    voice = ->(v) { summaries.find { |s| s["voice"] == v }&.dig("text") }

    save(Dossier::Profile.new(
      user: @user, display_name: name, third_person_name: name.split.first,
      headline: row["headline"], email: row["email"], phone: row["phone"],
      website_url: row["website_url"], linkedin_url: row["linkedin_url"], github_url: row["github_url"],
      location: location(row["location"], on: "Profile"),
      summary: row.dig("terse_summary", "text"),
      summary_first_person: voice.("first_person"), summary_third_person: voice.("third_person"),
      classification: :restricted
    ), "Profile")
  end

  # ── Engagements › Assignments ────────────────────────────────────────────

  def import_engagement(row)
    engagement = Dossier::Engagement.new(
      user: @user, employer: organisation(row["employer"]), position_title: row["position"].to_s,
      summary: row["description"], classification: :restricted, **date_attributes(row)
    )
    existing = @user.dossier_engagements.find_by(employer: engagement.employer, start_on: engagement.start_on) if engagement.employer
    if existing
      note_existing("Engagement", existing.to_toast_label, existing)
      engagement = existing
    else
      engagement.employment_type = reference(Dossier::EmploymentType, row["employment_type"],
                                             on: "Engagement #{engagement.to_toast_label}", required: true)
      return if engagement.employment_type.nil? && row["employment_type"].present? # unknown, already reported
      return unless save(engagement, "Engagement")
    end

    # A new permanent Engagement already has its Assignment; the first listed
    # one fills it in.
    reusable = engagement.assignments.first if existing.nil? && engagement.permanent?
    Array(row["assignments"]).each_with_index do |assignment_row, index|
      import_assignment(engagement, assignment_row, index.zero? ? reusable : nil)
    end
  end

  def import_assignment(engagement, row, reusable)
    assignment = reusable || Dossier::Assignment.new(engagement: engagement)
    assignment.assign_attributes(client: organisation(row["client"]), classification: :restricted, **date_attributes(row))
    assignment.role = reference(Dossier::Role, row["role"], on: "Assignment #{assignment.to_toast_label}")

    # Role is part of the match: one client can have two Assignments starting the same month.
    match = { client: assignment.client, start_on: assignment.start_on, role: assignment.role }
    if reusable.nil? && (existing = engagement.assignments.find_by(match))
      return note_existing("Assignment", existing.to_toast_label, existing)
    end

    assignment.assign_attributes(summary: row.dig("terse", "summary"), **tech_stack_attributes(row["tech_stack"] || {}))
    save(assignment, "Assignment")
  end

  # "2019-03" is month precision, a YAML date is day precision, "current"
  # (or nothing) is no end.
  def date_attributes(row)
    %w[start end].each_with_object({}) do |edge, attributes|
      value = row[edge]
      case value
      when Date
        attributes[:"#{edge}_month"] = value.strftime("%Y-%m")
        attributes[:"#{edge}_day"]   = value.day.to_s
      when nil, /\Acurrent\z/i
        attributes[:"#{edge}_month"] = ""
      else
        attributes[:"#{edge}_month"] = value.to_s
      end
    end
  end

  # Each list is an array, a comma-separated string or "N/A".
  def tech_stack_attributes(stack)
    attributes = { system_under_test: stack["system_under_test"].to_s }
    Dossier::TechStack::SLOTS.each_value do |plural|
      value = stack.fetch(plural.to_s) { stack[plural.to_s.singularize] }
      text = Array(value).join(", ")
      na = text.strip.casecmp?(NA)
      attributes[:"#{plural}_na"]   = na
      attributes[:"#{plural}_text"] = na ? "" : text
    end
    attributes
  end

  # ── Reference data ───────────────────────────────────────────────────────

  def reference(model, name, on:, required: false)
    name = name.to_s.strip
    return if name.empty?

    kind = model.model_name.human.titleize
    find_named(model, name) || (admin? ? save(model.new(name: name), kind, name) : unknown(kind, name, on, required))
  end

  def location(text, on:)
    return if text.blank?

    city, _, country = text.to_s.rpartition(",").map(&:strip)
    if city.empty? || country.empty?
      @warnings << "#{on}: can't read Location '#{text}' (expected 'City, Country') — left empty"
      return
    end

    Dossier::Location.find_by("LOWER(city) = ? AND LOWER(country) = ?", city.downcase, country.downcase) ||
      (admin? ? save(Dossier::Location.new(city: city, country: country), "Location", text) : unknown("Location", text, on, false))
  end

  def unknown(kind, name, on, required)
    if required
      @errors << "#{on}: unknown #{kind} '#{name}' — ask an Admin to add it"
    else
      @warnings << "#{on}: unknown #{kind} '#{name}' left empty"
    end
    nil
  end

  # ── Helpers ──────────────────────────────────────────────────────────────

  def admin? = @user.can_administer?

  def find_named(model, name)
    model.find_by("LOWER(name) = ?", name.downcase) unless name.empty?
  end

  def untag(text) = text.to_s.strip.sub(SOURCE_TAG, "")

  def save(record, kind, label = nil)
    unless record.save
      @errors << "#{kind} #{label || record.to_toast_label}: #{record.errors.full_messages.to_sentence}"
      return
    end

    @created_keys << [ record.class.name, record.id ]
    (@created[kind] ||= []) << (label || record.to_toast_label)
    record
  end

  # Records this import created itself aren't "already there".
  def note_existing(kind, label, record)
    (@existing[kind] ||= []) << label unless @created_keys.include?([ record.class.name, record.id ])
  end
end
