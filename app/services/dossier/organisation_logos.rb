# app/services/dossier/organisation_logos.rb

# One-off: attaches logos saved in a folder to Organisations. A file matches
# an Organisation when its name, less the extension and a trailing "logo", is
# the Organisation's name or abbreviation, ignoring case, spaces, underscores
# and punctuation ("APA Group.png", "QPT_logo.jpg", "Pinnacle_QM.jpeg"). An
# Organisation with a logo already is left alone, so it's safe to run again;
# a file matching two Organisations, or none, or that isn't a JPEG, PNG or
# WebP, is only reported. run! returns one line per file.
class Dossier::OrganisationLogos
  def initialize(dir)
    @dir = Pathname(dir)
  end

  def run!(dry_run: false)
    files.map { |path| place(path, dry_run: dry_run) }
  end

  private

  def files
    @dir.children.select { |path| path.file? && !path.basename.to_s.start_with?(".") }.sort
  end

  def place(path, dry_run:)
    name = path.basename.to_s
    return "Not a JPEG, PNG or WebP: #{name}" unless Dossier::Organisation::LOGO_TYPES.include?(Marcel::MimeType.for(path))

    matches = organisations_named(path.basename(path.extname).to_s)
    return "No match: #{name}" if matches.empty?
    return "Ambiguous, matches #{matches.map(&:name).sort.join(' and ')}: #{name}" if matches.size > 1

    organisation = matches.first
    return "Skipped, already has a logo: #{name} → #{organisation.name}" if organisation.logo.attached?

    organisation.logo.attach(io: path.open, filename: name) unless dry_run
    "Attached: #{name} → #{organisation.name}"
  end

  def organisations_named(stem)
    key = normalise(stem.sub(/[\s_-]*logo\z/i, ""))
    organisations.select { |_, keys| keys.include?(key) }.map(&:first)
  end

  # [[organisation, [name, abbreviation]], …], normalised.
  def organisations
    @organisations ||= Dossier::Organisation.includes(logo_attachment: :blob).map do |organisation|
      [ organisation, [ organisation.name, organisation.abbreviation ].compact.map { |key| normalise(key) } ]
    end
  end

  # Letters and digits only, so "Pinnacle_QM" and "PinnacleQM" meet.
  def normalise(text) = text.unicode_normalize(:nfc).downcase.gsub(/[^[:alnum:]]/, "")
end
