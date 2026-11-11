# app/services/dossier/linkedin_scan.rb

# Turns a LinkedIn data export's connections (Connections.csv, in the export's
# zip) into the manifest that Dossier::LinkedinImport applies, for review in
# between. Each connection keeps its name as LinkedIn has it and a cleaned
# first and last name (no emoji, nicknames, "(She/Her)", or credentials such
# as ", MBA" or "PRINCE2"), its profile URL, company, position and the day
# you connected. Hidden members (no name) are left out; one profile listed
# twice is kept once.
#
# Each connection also suggests the user's Assignments you may have worked on
# together: their current company is the Assignment's client, employer,
# vendor or customer, and you connected while it ran or within three months
# of its end. Only a suggestion: their company is today's, not then's, and
# the import never adds Colleagues.
class Dossier::LinkedinScan
  CONNECTIONS = "Connections.csv"
  HEADER = "First Name,"
  AFTER_END = 3.months
  # Dropped from company names before they're compared.
  COMPANY_SUFFIXES = /\b(pty|ltd|limited|inc|llc|ab|plc|group|australia|sweden|corporation|corp|co)\b/
  CREDENTIAL = /\A(?=.*[A-Z]{2})[A-Z0-9®™.&-]+\z/

  # archives: export zips, read in order until one has the connections.
  # read: (archive, member) → its text, or nil (unzip by default).
  def initialize(archives, user:, today: Date.current, read: method(:unzip))
    @archives = Array(archives)
    @user = user
    @today = today
    @read = read
  end

  # Cleans one LinkedIn name part: emoji, quoted or bracketed nicknames,
  # anything after a comma or slash, and (in a last name) trailing credentials.
  def self.clean_name(text, last: false)
    text = text.to_s.gsub(/"[^"]*"|\([^)]*\)|\[[^\]]*\]/, " ").split(%r{[,/|]}).first.to_s
    words = text.gsub(/[\u{FE00}-\u{FE0F}\u200D]/, "").gsub(/[^\p{L}\p{M}\s'’.-]/, " ").squish.split
    words.pop while last && words.size > 1 && words.last.match?(CREDENTIAL)
    words.join(" ")
  end

  # Manifest entries (string-keyed hashes), in the export's order.
  def connections
    rows.filter_map { |row| entry(row) }.uniq { |entry| entry["linkedin"].presence || entry["name_on_linkedin"] }
  end

  def to_yaml = { "source" => @archives.map(&:to_s), "connections" => connections }.to_yaml

  # The suggested Colleagues, by Assignment (in the order the export lists them), as Markdown.
  def suggestions_markdown
    found = connections.flat_map { |entry| entry["suggested"].map { |suggestion| [ suggestion, entry ] } }
    lines = [ "# Suggested Colleagues from LinkedIn", "",
              "#{found.size} suggestions: their current company was on the Assignment, and you connected while it ran " \
              "(or within three months). Add the right ones on each Assignment's page.", "" ]
    found.group_by { |suggestion, _| suggestion["assignment_id"] }.each_value do |pairs|
      lines << "## #{pairs.first.first['assignment']}" << ""
      lines << "| Name | Company | Position | Connected |" << "|---|---|---|---|"
      pairs.each do |_, entry|
        name = "[#{entry['first_name']} #{entry['last_name']}](#{entry['linkedin']})"
        lines << "| #{[ name, entry['company'], entry['position'], entry['connected_on'] ].map { |cell| cell.to_s.tr('|', '/') }.join(' | ')} |"
      end
      lines << ""
    end
    lines.join("\n")
  end

  private

  def rows
    text = @archives.lazy.filter_map { |archive| @read.call(archive, CONNECTIONS) }.first.to_s
    lines = text.lines
    start = lines.index { |line| line.start_with?(HEADER) }
    start ? CSV.parse(lines.drop(start).join, headers: true).map(&:to_h) : []
  end

  def entry(row)
    first = self.class.clean_name(row["First Name"])
    last = self.class.clean_name(row["Last Name"], last: true)
    return if first.empty? && last.empty?

    first, last = last, "" if first.empty?
    connected_on = parse_date(row["Connected On"])
    { "name_on_linkedin" => [ row["First Name"], row["Last Name"] ].compact.join(" ").squish,
      "first_name" => first, "last_name" => last.presence,
      "linkedin" => row["URL"].presence, "company" => row["Company"].presence, "position" => row["Position"].presence,
      "connected_on" => connected_on&.iso8601, "suggested" => suggestions(row["Company"], connected_on) }
  end

  def parse_date(text)
    Date.strptime(text.to_s.strip, "%d %b %Y")
  rescue Date::Error
    nil
  end

  def suggestions(company, connected_on)
    company = normalise_company(company)
    return [] if company.length < 3 || connected_on.nil?

    assignments.filter_map do |assignment, organisations, period|
      next unless period.cover?(connected_on) && organisations.any? { |name| same_company?(name, company) }

      { "assignment_id" => assignment.id, "assignment" => label(assignment) }
    end
  end

  def same_company?(name, company)
    return false if name.length < 3

    name == company || company.match?(/\b#{Regexp.escape(name)}\b/) || name.match?(/\b#{Regexp.escape(company)}\b/)
  end

  def normalise_company(name)
    name.to_s.downcase.gsub(/[^a-z0-9&\s]/, " ").gsub(COMPANY_SUFFIXES, " ").squish
  end

  # [[assignment, normalised organisation names, the days you'd have met]…]
  def assignments
    @assignments ||= Dossier::Assignment.kept.where(user_id: @user.id, engagement: Dossier::Engagement.kept)
                                             .includes(:client, :role, engagement: :employer, partners: :organisation)
                                             .order(:start_on).map do |assignment|
      names = [ assignment.client, assignment.engagement.employer, *assignment.partners.map(&:organisation) ]
              .compact.map { |organisation| normalise_company(organisation.name) }.uniq
      [ assignment, names, assignment.start_on..((assignment.end_on || @today) + AFTER_END) ]
    end
  end

  def label(assignment)
    dates = [ assignment.start_on, assignment.end_on ].map { |date| date&.strftime("%b %Y") || "now" }.join(" – ")
    "#{assignment.to_toast_label} (#{assignment.engagement.employer.name}, #{dates})"
  end

  def unzip(archive, member)
    text, status = Open3.capture2("unzip", "-p", archive.to_s, member)
    status.success? && text.present? ? text.force_encoding("UTF-8") : nil
  rescue Errno::ENOENT
    nil
  end
end
