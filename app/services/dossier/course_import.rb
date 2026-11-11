# app/services/dossier/course_import.rb

# Applies a reviewed course manifest (see Dossier::CourseScan) to one user's
# Credentials, and the course providers' descriptions
# (db/seeds/dossier/course_providers.yml) to the shared Organisations, in one
# transaction, returning what changed. Missing providers are added; a written
# description is kept. A course matching one of the user's training
# Credentials by title (any case) only fills that one's blanks: provider,
# certificate number, verification URL, Skills and certificates. Others are
# added as Courses with their certificates attached. A dry run reports the
# same changes and saves nothing (no file is stored either).
class Dossier::CourseImport
  class Error < StandardError; end

  def initialize(manifest, providers:, user:)
    @root = Pathname(manifest.fetch("root"))
    @courses = Array(manifest["courses"])
    @providers = Array(providers)
    @user = user
    @report = []
  end

  def apply!(dry_run: false)
    ActiveRecord::Base.transaction do
      @dry_run = dry_run
      @providers.each { |row| describe_provider(row) }
      @courses.each { |row| apply_course(row) }
      raise ActiveRecord::Rollback if dry_run
    end
    @report
  end

  private

  def note(line) = @report << line

  def describe_provider(row)
    organisation = find_provider(row["name"])
    if organisation.nil?
      Dossier::Organisation.create!(name: row["name"], description: row["description"])
      note "Added provider #{row['name']}"
    elsif organisation.description.blank? && row["description"].present?
      organisation.update!(description: row["description"])
      note "Described #{organisation.name}"
    end
  end

  def find_provider(name)
    name.presence && Dossier::Organisation.find_by("LOWER(name) = ?", name.downcase)
  end

  def provider_for(name)
    return if name.blank?

    find_provider(name) || Dossier::Organisation.create!(name: name).tap { note "Added provider #{name}" }
  end

  def apply_course(row)
    files = certificates(row)
    existing = @user.dossier_credentials.training.find_by("LOWER(dossier_credentials.title) = ?", row["title"].to_s.downcase)
    existing ? update_course(existing, row, files) : add_course(row, files)
  end

  def add_course(row, files)
    credential = @user.dossier_credentials.build(
      credential_type: course_type, title: row["title"], provider: provider_for(row["provider"]), status: row["status"],
      start_on: row["started"], start_precision: row["precision"] || "month",
      end_on: row["completed"], end_precision: row["precision"] || "month",
      certificate_number: row["certificate_number"], verification_url: row["verification_url"],
      skills_text: Array(row["skills"]).join(", ")
    )
    save(credential, row)
    attach(credential, files)
    note "Added #{credential.title} (#{credential.status_label}, #{files.size} #{'certificate'.pluralize(files.size)})"
  end

  def update_course(credential, row, files)
    filled = []
    if credential.provider.nil? && row["provider"].present?
      credential.provider = provider_for(row["provider"])
      filled << "provider"
    end
    { "certificate_number" => "certificate number", "verification_url" => "verification URL" }.each do |key, label|
      next if credential[key].present? || row[key].blank?

      credential[key] = row[key]
      filled << label
    end
    if credential.credential_skills.empty? && Array(row["skills"]).any?
      credential.skills_text = row["skills"].join(", ")
      filled << "Skills"
    end
    files = [] if credential.files.attached?
    filled << "certificate".pluralize(files.size) if files.any?
    return if filled.empty?

    save(credential, row)
    attach(credential, files)
    note "Updated #{credential.title}: #{filled.join(', ')}"
  end

  def save(credential, row)
    return if credential.save

    raise Error, "#{row['folder'] || row['title']}: #{credential.errors.full_messages.to_sentence}"
  end

  # Stored only for real: a dry run is rolled back, but stored files wouldn't be.
  def attach(credential, files)
    return if @dry_run || files.empty?

    files.each { |path| credential.files.attach(io: path.open("rb"), filename: path.basename.to_s) }
  end

  def certificates(row)
    Array(row["certificates"]).filter_map do |relative|
      path = @root.join(relative)
      next path if path.file?

      note "Missing certificate #{relative}"
      nil
    end
  end

  def course_type
    @course_type ||= Dossier::CredentialType.find_by("LOWER(name) = ?", "course") ||
                     raise(Error, "There's no Course Credential Type to add courses as.")
  end
end
