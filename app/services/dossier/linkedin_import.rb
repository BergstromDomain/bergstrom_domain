# app/services/dossier/linkedin_import.rb

# Applies a reviewed LinkedIn manifest (see Dossier::LinkedinScan) to People,
# in one transaction, returning what changed. Each connection becomes a
# Restricted Person of the user's with their LinkedIn profile and, as the
# description, their position and company. Someone already in People under
# the same full name (any case) gets only their blanks filled, and only when
# they're the user's: another user's Person is left alone. Emails and the
# suggested Assignments aren't imported; Colleagues are added by hand. A dry
# run reports the same changes and saves nothing.
class Dossier::LinkedinImport
  class Error < StandardError; end

  def initialize(manifest, user:)
    @connections = Array(manifest["connections"])
    @user = user
    @report = []
  end

  def apply!(dry_run: false)
    ActiveRecord::Base.transaction do
      @people = Person.includes(person_social_media_accounts: :social_media_platform)
                      .index_by { |person| person.full_name.downcase }
      @connections.each { |row| apply_connection(row) }
      raise ActiveRecord::Rollback if dry_run
    end
    @report
  end

  private

  def note(line) = @report << line

  def apply_connection(row)
    person = Person.new(first_name: row["first_name"].to_s.squish, last_name: row["last_name"].to_s.squish.presence)
    return note("Skipped #{row['name_on_linkedin']}: no first name") if person.first_name.empty?

    existing = @people[person.full_name.downcase]
    if existing.nil?
      add_person(person, row)
    elsif existing.user_id == @user.id
      fill_person(existing, row)
    else
      note "Skipped #{existing.full_name}: someone else's Person"
    end
  end

  def add_person(person, row)
    person.assign_attributes(user: @user, classification: "restricted", description: description(row))
    person.linkedin_url = row["linkedin"] if row["linkedin"].present?
    save(person, row)
    @people[person.full_name.downcase] = person
    note "Added #{person.full_name}"
  end

  def fill_person(person, row)
    filled = []
    if person.linkedin_url.nil? && row["linkedin"].present?
      person.linkedin_url = row["linkedin"]
      filled << "LinkedIn"
    end
    if person.description.blank? && (text = description(row))
      person.description = text
      filled << "description"
    end
    return if filled.empty?

    save(person, row)
    note "Updated #{person.full_name}: #{filled.join(', ')}"
  end

  # "Test Manager at Elysium Digital", or whichever of the two there is.
  def description(row)
    [ row["position"], row["company"] ].map(&:presence).compact.join(" at ").presence
  end

  def save(person, row)
    return if person.save

    raise Error, "#{row['name_on_linkedin'] || person.full_name}: #{person.errors.full_messages.to_sentence}"
  end
end
