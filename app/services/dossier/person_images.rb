# app/services/dossier/person_images.rb

# Attaches photos saved in a folder to the user's own People (Occasions), for
# Dossier's contact thumbnails. A file matches a Person when its name, less
# the extension, is the Person's full name or their LinkedIn username, in any
# case. LinkedIn's export has no photos, so they're saved by hand. A Person
# who already has an image is left alone, so it's safe to run again; a file
# matching two People, or none, or that isn't a JPEG, PNG or WebP, is only
# reported. run! returns one line per file.
class Dossier::PersonImages
  TYPES = %w[image/jpeg image/png image/webp].freeze

  def initialize(user, dir)
    @user = user
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
    return "Not a JPEG, PNG or WebP: #{name}" unless TYPES.include?(Marcel::MimeType.for(path))

    people = matches(path.basename(path.extname).to_s)
    return "No match: #{name}" if people.empty?
    return "Ambiguous, matches #{people.map(&:full_name).sort.join(' and ')}: #{name}" if people.size > 1

    person = people.first
    return "Skipped, already has an image: #{name} → #{person.full_name}" if person.image.attached?

    person.image.attach(io: path.open, filename: name) unless dry_run
    "Attached: #{name} → #{person.full_name}"
  end

  def matches(stem)
    key = normalise(stem)
    people.select { |person, keys| keys.include?(key) }.map(&:first)
  end

  # [[person, [full name, LinkedIn username]], …], normalised.
  def people
    @people ||= Person.where(user: @user).includes(:image_attachment, person_social_media_accounts: :social_media_platform)
                      .map { |person| [ person, [ person.full_name, linkedin_username(person) ].compact.map { |key| normalise(key) } ] }
  end

  def linkedin_username(person)
    person.linkedin_url.to_s[Person::LINKEDIN_PROFILE, 1]
  end

  def normalise(text) = text.unicode_normalize(:nfc).squish.downcase
end
