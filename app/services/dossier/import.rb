# app/services/dossier/import.rb

# Imports a Bridge CV master list (master_cv.yaml) into the user's Dossier:
# Profile, Organisations, Skills, then Engagements › Assignments with their
# Tech Stack and terse achievements, then Credentials (education,
# certifications, training). Fields that aren't CV data (notes, src,
# linkedin…) are never read. A record that already exists is skipped, never updated, so a
# re-import keeps edits made in the app. An Assignment's vendors become
# private Vendor links, with their staff as private Staff members (never on
# a CV); a re-import adds missing ones to an existing Assignment, like its
# achievements.
#
# All or nothing: #preview runs the whole import and rolls it back, so the
# preview and #import! can't disagree; any error rolls #import! back too.
# Admin-only reference data (Employment Types, Roles, Industries, Locations,
# Skill Categories, Credential Types) is created only for an Admin — anyone else gets an error
# (required) or a warning (optional) instead.
class Dossier::Import
  Result = Struct.new(:created, :existing, :warnings, :errors, keyword_init: true) do
    def ok? = errors.empty?
  end

  SECTIONS = %w[profile organisations skills engagements credentials].freeze

  # The Credential Type each credentials list imports as, unless a row names
  # its own (type:). An education row that isn't a degree (an exchange
  # semester) is a Course; a thesis goes in its degree's description.
  CREDENTIAL_LISTS = { "education" => "Degree", "certifications" => "Certification", "training" => "Course" }.freeze
  DEGREE_TITLE = /degree|bachelor|master of|diploma|doctor|ph\.?d/i
  THESIS_TITLE = /\A(?:\w+ )?thesis\b/i
  NA = "N/A"
  # A vendor's staff: YAML key → Dossier::StaffMember attribute, and → its
  # Person's (a mobile isn't kept).
  STAFF_FIELDS = { "position" => :position, "comment" => :comment }.freeze
  STAFF_PERSON_FIELDS = { "email" => :work_email, "linkedin" => :linkedin_url }.freeze

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
    @created_keys, @existing_keys = Set.new, Set.new
    @skill_categories = {}

    if (data = parse)
      # requires_new: a plain nested transaction ignores ActiveRecord::Rollback.
      ActiveRecord::Base.transaction(requires_new: true) do
        import_all(data)
        raise ActiveRecord::Rollback unless commit && @errors.empty?
      end
    end

    Result.new(created: @created, existing: @existing, warnings: @warnings, errors: @errors)
  end

  def parse
    data = YAML.safe_load(@text.to_s, permitted_classes: [ Date ], aliases: true)
    return data if data.is_a?(Hash) && data.keys.intersect?(SECTIONS)

    @errors << "Not a master list: expected profile, organisations, skills, engagements or credentials"
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
    import_credentials(data["credentials"]) if data["credentials"].is_a?(Hash)
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
    number_by_date(engagement) if existing.nil?
  end

  # A new Engagement's Assignments start newest first, as the Timeline listed
  # them before they could be re-sorted, whatever order the file gives.
  def number_by_date(engagement)
    engagement.assignments.reload
              .sort_by { |assignment| [ assignment.effective_end || Date.current, assignment.start_on ] }.reverse
              .each_with_index { |assignment, index| assignment.update_columns(position: index + 1) }
  end

  def import_assignment(engagement, row, reusable)
    assignment = reusable || Dossier::Assignment.new(engagement: engagement)
    assignment.assign_attributes(client: organisation(row["client"]), classification: :restricted, **date_attributes(row))
    assignment.role = reference(Dossier::Role, row["role"], on: "Assignment #{assignment.to_toast_label}")

    # Role is part of the match: one client can have two Assignments starting the same month.
    # A deleted one counts too, so a re-import doesn't bring it back as a duplicate.
    match = { client: assignment.client, start_on: assignment.start_on, role: assignment.role }
    if reusable.nil? && (existing = engagement.all_assignments.find_by(match))
      note_existing("Assignment", existing.to_toast_label, existing)
      assignment = existing
    else
      assignment.assign_attributes(project: row["project"], summary: row.dig("terse", "summary"),
                                   **tech_stack_attributes(row["tech_stack"] || {}))
      return unless save(assignment, "Assignment")
    end

    import_achievements(assignment, row.dig("terse", "achievements"))
    import_vendors(assignment, row["vendors"])
  end

  # vendors: "N/A", or a list of names or { name, project, scope }. Scope is
  # "Project – scope" (either alone if the other is missing).
  def import_vendors(assignment, rows)
    return unless rows.is_a?(Array)

    rows.each do |row|
      row = { "name" => row } unless row.is_a?(Hash)
      next unless (vendor = organisation(row["name"]))

      label = "#{vendor.name} on #{assignment.to_toast_label}"
      if (partner = assignment.partners.vendor.find_by(organisation: vendor))
        note_existing("Vendor", label, partner)
      else
        scope = [ row["project"], row["scope"] ].map { |part| part.to_s.strip }.reject(&:empty?).join(" – ")
        partner = save(assignment.partners.build(kind: "vendor", organisation: vendor, scope: scope), "Vendor", label)
      end
      import_staff(partner, label, row["staff"]) if partner
    end
  end

  # staff: a vendor's list of { name, position, email, linkedin, comment }
  # (a mobile is ignored). Each is a Person: the one of that full name (any
  # case), else a new Restricted one with the email and LinkedIn. Matched by
  # name, so a re-import adds only new ones.
  def import_staff(partner, partner_label, rows)
    return unless rows.is_a?(Array)

    rows.each do |row|
      next unless row.is_a?(Hash) && (name = row["name"].to_s.squish).present?

      label = "#{name} at #{partner_label}"
      if (existing = partner.staff_members.includes(:person).find { |member| member.name.casecmp?(name) })
        note_existing("Staff Member", label, existing)
      else
        member = partner.staff_members.build(STAFF_FIELDS.to_h { |key, attribute| [ attribute, row[key].to_s ] })
        member.person = staff_person(name, row)
        save(member, "Staff Member", label)
      end
    end
  end

  def staff_person(name, row)
    Person.all.find { |person| person.full_name.casecmp?(name) } || begin
      *first, last = name.split
      first, last = [ last ], nil if first.empty?
      Person.new(first_name: first.join(" "), last_name: last, user: @user, classification: "restricted",
                 **STAFF_PERSON_FIELDS.to_h { |key, attribute| [ attribute, row[key].to_s ] })
    end
  end

  # Matched by exact text, deleted ones included, so an existing Assignment
  # still gets new ones and a deleted one stays deleted.
  def import_achievements(assignment, texts)
    Array(texts).map { |text| text.to_s.strip }.reject(&:empty?).each do |text|
      if (existing = assignment.all_achievements.find_by(text: text))
        note_existing("Achievement", existing.to_toast_label, existing)
      else
        save(assignment.all_achievements.build(text: text, importance: 3, classification: :restricted), "Achievement")
      end
    end
  end

  # ── Credentials ──────────────────────────────────────────────────────────

  def import_credentials(lists)
    CREDENTIAL_LISTS.each do |list, default_type|
      degree = nil
      Array(lists[list]).each do |row|
        title = row["title"].to_s.strip
        next if title.empty?

        if list == "education" && title.match?(THESIS_TITLE)
          add_thesis(degree, title, row)
        else
          type = row["type"] || (list == "education" && !title.match?(DEGREE_TITLE) ? "Course" : default_type)
          credential = import_credential(title, type, row)
          degree = credential if list == "education" && type == "Degree"
        end
      end
    end
  end

  # Returns the new Credential, or nil when it already exists or was skipped.
  def import_credential(title, type_name, row)
    if (existing = @user.dossier_credentials.find_by("LOWER(title) = ?", title.downcase))
      return note_existing("Credential", existing.title, existing) && nil
    end

    unless (date = credential_date(row))
      @warnings << "Credential #{title}: no year or date — skipped"
      return
    end

    type = reference(Dossier::CredentialType, type_name, on: "Credential #{title}", required: true)
    return unless type

    renewals = Array(row["years"]).map(&:to_s) - [ date[0, 4] ]
    save(Dossier::Credential.new(
      user: @user, credential_type: type, title: title, classification: :restricted,
      provider: (organisation(row["issuer"]) unless row["issuer"].to_s.strip == "?"),
      certificate_number: row["licence"], description: ("Renewed #{renewals.join(', ')}." if renewals.any?),
      start_month: date, end_month: date, start_day: credential_day(row), end_day: credential_day(row)
    ), "Credential", title)
  end

  # completed (an exact date), then date ("2009-08"), then year ("2001").
  def credential_date(row)
    value = row["completed"] || row["date"] || row["year"]
    value = value.strftime("%Y-%m") if value.is_a?(Date)
    value.to_s.strip if value.to_s.strip.match?(/\A\d{4}(-\d{2})?\z/)
  end

  def credential_day(row) = row["completed"].is_a?(Date) ? row["completed"].day.to_s : ""

  # Only a degree this import created gets the thesis: an existing one keeps
  # its edits.
  def add_thesis(degree, title, row)
    unless degree
      @warnings << "#{title}: no new degree before it to add it to — skipped"
      return
    end

    text = title.split(":", 2).last.strip
    text += ", supervised at #{row['supervised_at']}" if row["supervised_at"].present?
    text += " (#{row['year']})" if row["year"].present?
    degree.update!(description: [ degree.description, "Thesis: #{text}." ].compact.join("\n\n"))
  end

  # "2019-03" is month precision, a YAML date is day precision, "current"
  # (or nothing) is no end. The day is always set, so a reused permanent
  # Assignment doesn't keep its Engagement's exact day.
  def date_attributes(row)
    %w[start end].each_with_object({}) do |edge, attributes|
      value = row[edge]
      month, day = case value
      when Date then [ value.strftime("%Y-%m"), value.day.to_s ]
      when nil, /\Acurrent\z/i then [ "", "" ]
      else [ value.to_s, "" ]
      end
      attributes[:"#{edge}_month"] = month
      attributes[:"#{edge}_day"]   = day
    end
  end

  # Each list is an array, a comma-separated string or "N/A", under its
  # plural or singular name (methodology, system_under_test).
  def tech_stack_attributes(stack)
    attributes = {}
    Dossier::TechStack::SLOTS.each do |slot, plural|
      value = stack.fetch(plural.to_s) { stack[slot.to_s] }
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

  # Listed once per record (an Organisation can be named many times), and
  # records this import created itself aren't "already there".
  def note_existing(kind, label, record)
    key = [ record.class.name, record.id ]
    return if @created_keys.include?(key) || !@existing_keys.add?(key)

    (@existing[kind] ||= []) << label
  end
end
