# app/helpers/dossier_helper.rb
module DossierHelper
  # The page for a Timeline bench or gap period (a Dossier::Timeline::Period).
  def period_path_for(period)
    dossier_period_path(from: period.from.iso8601, to: period.to.iso8601)
  end

  # A link opening url in a new tab, but only for http(s): anything else is
  # shown as plain text, so a javascript: URL can never become an href.
  def external_link(url)
    return "—" if url.blank?
    return ERB::Util.html_escape(url) unless url.match?(%r{\Ahttps?://}i)

    link_to url, url, target: "_blank", rel: "noopener"
  end

  # "Windows (XP, 7)" for a Dossier::AssignmentTechStack::Family, each Skill
  # linked; families joined with commas. One span, so a flex cell's gap
  # doesn't land before each comma.
  def skill_family_links(families)
    links = families.map do |family|
      root = link_to(family.root.display_name, dossier_skill_path(family.root))
      next root if family.versions.empty?

      versions = family.versions.map { |version| link_to(version.version_label, dossier_skill_path(version)) }
      safe_join([ root, " (", safe_join(versions, ", "), ")" ])
    end
    tag.span(safe_join(links, ", "))
  end

  # What the Profile's three summaries are for, for an info tip.
  def profile_summaries_info
    safe_join([
      tag.strong("Summary"), " is the terse form, with no \"I\" and no name: \"Test manager with 25+ years…\". ",
      "CVs use it wherever a voice has no version of its own. ",
      tag.strong("First-Person Summary"), " speaks as you, \"I lead…\", for cover letters and LinkedIn. ",
      tag.strong("Third-Person Summary"), " uses your Third-Person Name, \"Alex leads…\", for bios and introductions."
    ])
  end

  # Where a Skill was used on an Assignment, in display order: the Tech Stack
  # lists, then other uses, then Achievement tags only.
  SKILL_USES = Dossier::TechStack::SLOTS.keys + %i[other achievement]

  def skill_use_label(use)
    plural = Dossier::TechStack::SLOTS[use]
    return Dossier::TechStack::LABELS.fetch(plural) if plural

    use == :achievement ? "Tagged On Achievements" : "Other"
  end

  # "5 (highest)" … "3 (default)" … "1 (lowest)".
  def importance_label(importance)
    note = { 5 => "highest", 3 => "default", 1 => "lowest" }[importance]
    note ? "#{importance} (#{note})" : importance.to_s
  end

  # Taken During for a Credential with no Engagement or Assignment.
  PERSONAL_DEVELOPMENT = "Personal Development"

  # Where a Credential was taken: a link to its Assignment or Engagement, else
  # "Personal Development".
  def credential_taken_during(credential, assignment_label: :heading)
    if credential.assignment
      link_to credential.assignment.public_send(assignment_label), dossier_assignment_path(credential.assignment)
    elsif credential.engagement
      link_to credential.engagement.to_toast_label, dossier_engagement_path(credential.engagement)
    else
      PERSONAL_DEVELOPMENT
    end
  end

  # The text credential_taken_during shows, for sorting.
  def credential_taken_during_label(credential)
    credential.assignment&.heading || credential.engagement&.to_toast_label || PERSONAL_DEVELOPMENT
  end

  # A Credentials table's column heading: a link sorting by it (again to
  # reverse), with an arrow on the active column. Plain text without a sort.
  def credential_sort_link(sort, column)
    label = Dossier::CredentialSort::COLUMNS.fetch(column)
    return label if sort.nil?

    active = sort.active?(column)
    direction = active && sort.direction == "asc" ? "desc" : "asc"
    arrow = active ? (sort.direction == "asc" ? " ▲" : " ▼") : ""
    query = request.query_parameters.merge("sort" => column, "direction" => direction)
    link_to "#{label}#{arrow}", "#{request.path}?#{query.to_query}", data: { testid: "sort-#{column}" }
  end
end
