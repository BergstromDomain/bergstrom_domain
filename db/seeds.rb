# db/seeds.rb

SEED_IMAGES = Rails.root.join("db/seed_images")

def attach_seed_image(record, attachment_name, key)
  return if record.public_send(attachment_name).attached?

  record.public_send(attachment_name).attach(
    io: File.open(SEED_IMAGES.join("#{key}.png")),
    filename: "#{key}.png",
    content_type: "image/png"
  )
end

# ── Admin user ──────────────────────────────────────────────────────────────
user = User.find_or_create_by!(email_address: Rails.application.credentials.admin_email) do |u|
  u.password = Rails.application.credentials.admin_password
  u.password_confirmation = Rails.application.credentials.admin_password
end

user.update!(role: "system_admin")

# ── Event Types ─────────────────────────────────────────────────────────────
event_types = {
  birthday:  EventType.find_or_create_by!(name: "Birthday")  { |et| et.description = "Birthday celebrations"; et.icon = "cake" },
  education: EventType.find_or_create_by!(name: "Education") { |et| et.description = "Educational milestones"; et.icon = "graduation-cap" },
  work:      EventType.find_or_create_by!(name: "Work")      { |et| et.description = "Career and work events"; et.icon = "briefcase" },
  sport:     EventType.find_or_create_by!(name: "Sport")     { |et| et.description = "Sporting events"; et.icon = "trophy" },
  wedding:   EventType.find_or_create_by!(name: "Wedding")   { |et| et.description = "Weddings and ceremonies"; et.icon = "heart" },
  music:     EventType.find_or_create_by!(name: "Music")     { |et| et.description = "Musical releases and concerts"; et.icon = "music" }
}

# ── Named test personas (spec/support/authentication_helpers.rb) ────────────
# Pat Pending and Gary Guest aren't included here — Pat has no content to own,
# and Gary Guest is unauthenticated (no account at all).
def find_or_create_persona!(first_name:, last_name:, email_address:, status:, role:, image_key:)
  persona = User.find_or_create_by!(email_address: email_address) do |u|
    u.first_name = first_name
    u.last_name  = last_name
    u.password = "password123"
    u.password_confirmation = "password123"
    u.status = status
    u.role = role
  end
  attach_seed_image(persona, :profile_image, image_key)
  persona
end

pat_pending = find_or_create_persona!(first_name: "Pat", last_name: "Pending", email_address: "pat.pending@example.com",
                                       status: "pending", role: "app_user", image_key: "pat_pending")
sue_suspended = find_or_create_persona!(first_name: "Sue", last_name: "Suspended", email_address: "sue.suspended@example.com",
                                         status: "suspended", role: "app_user", image_key: "sue_suspended")
uno_user = find_or_create_persona!(first_name: "Uno", last_name: "User", email_address: "uno.user@example.com",
                                    status: "active", role: "app_user", image_key: "uno_user")
ulrika_user = find_or_create_persona!(first_name: "Ulrika", last_name: "User", email_address: "ulrika.user@example.com",
                                       status: "active", role: "app_user", image_key: "ulrika_user")
charlie_creator = find_or_create_persona!(first_name: "Charlie", last_name: "Creator", email_address: "charlie.creator@example.com",
                                           status: "active", role: "content_creator", image_key: "charlie_creator")
chris_creator = find_or_create_persona!(first_name: "Chris", last_name: "Creator", email_address: "chris.creator@example.com",
                                         status: "active", role: "content_creator", image_key: "chris_creator")
curtis_creator = find_or_create_persona!(first_name: "Curtis", last_name: "Creator", email_address: "curtis.creator@example.com",
                                          status: "active", role: "content_creator", image_key: "curtis_creator")
adam_admin = find_or_create_persona!(first_name: "Adam", last_name: "Admin", email_address: "adam.admin@example.com",
                                      status: "active", role: "admin", image_key: "adam_admin")
sam_sysadmin = find_or_create_persona!(first_name: "Sam", last_name: "SysAdmin", email_address: "sam.sysadmin@example.com",
                                        status: "active", role: "system_admin", image_key: "sam_sysadmin")

# ── People — Metallica members ───────────────────────────────────────────────
# Owned by Adam Admin (a named test persona, distinct from the real admin
# account created above from encrypted credentials).
people = {
  hetfield: Person.find_or_create_by!(first_name: "James",  middle_name: nil, last_name: "Hetfield")  { |p| p.user = adam_admin },
  ulrich:   Person.find_or_create_by!(first_name: "Lars",   middle_name: nil, last_name: "Ulrich")    { |p| p.user = adam_admin },
  hammett:  Person.find_or_create_by!(first_name: "Kirk",   middle_name: nil, last_name: "Hammett")   { |p| p.user = adam_admin },
  trujillo: Person.find_or_create_by!(first_name: "Robert", middle_name: nil, last_name: "Trujillo")  { |p| p.user = adam_admin }
}
people.each_value { |p| p.update!(user: adam_admin) unless p.user_id == adam_admin.id }

# ── Events — Metallica albums ─────────────────────────────────────────────────
metallica_albums = [
  { title: "Kill 'Em All",                        day: 25, month: 7,  year: 1983 },
  { title: "Ride the Lightning",                  day: 27, month: 7,  year: 1984 },
  { title: "Master of Puppets",                   day: 3,  month: 3,  year: 1986 },
  { title: "...And Justice for All",              day: 25, month: 8,  year: 1988 },
  { title: "Metallica (Black Album)",             day: 12, month: 8,  year: 1991 },
  { title: "Load",                                day: 4,  month: 6,  year: 1996 },
  { title: "Reload",                              day: 18, month: 11, year: 1997 },
  { title: "St. Anger",                           day: 5,  month: 6,  year: 2003 },
  { title: "Death Magnetic",                      day: 12, month: 9,  year: 2008 },
  { title: "Hardwired... to Self-Destruct",       day: 18, month: 11, year: 2016 },
  { title: "72 Seasons",                          day: 14, month: 4,  year: 2023 }
]

metallica_albums.each do |attrs|
  event = Event.find_or_initialize_by(title: attrs[:title])
  event.assign_attributes(
    day:        attrs[:day],
    month:      attrs[:month],
    year:       attrs[:year],
    event_type: event_types[:music],
    user:       adam_admin
  )

  event.people << people[:hetfield] unless event.people.include?(people[:hetfield])
  event.save!
end

# ── Franchise character sets ─────────────────────────────────────────────────
# Charlie likes Harry Potter, Chris likes Lord of the Rings, Curtis likes Star
# Wars, Sue likes Tom Clancy's Jack Ryan — each owns their franchise's people
# (given a distinct classification per franchise) and each person gets 3
# events with a random type and date.
FRANCHISES = [
  {
    owner: charlie_creator,
    classification: "unrestricted",
    prefix: "hp",
    characters: [
      %w[Harry Potter], %w[Hermione Granger], %w[Ron Weasley], %w[Albus Dumbledore],
      %w[Severus Snape], %w[Draco Malfoy], %w[Rubeus Hagrid], %w[Minerva McGonagall],
      %w[Sirius Black], %w[Luna Lovegood]
    ]
  },
  {
    owner: chris_creator,
    classification: "contacts",
    prefix: "lotr",
    characters: [
      %w[Frodo Baggins], %w[Samwise Gamgee], [ "Gandalf", "" ], %w[Aragorn Elessar],
      [ "Legolas", "" ], [ "Gimli", "" ], %w[Boromir Gondor], %w[Meriadoc Brandybuck],
      %w[Peregrin Took], [ "Galadriel", "" ]
    ]
  },
  {
    owner: curtis_creator,
    classification: "restricted",
    prefix: "sw",
    characters: [
      %w[Luke Skywalker], %w[Leia Organa], %w[Han Solo], %w[Darth Vader],
      [ "Obi-Wan", "Kenobi" ], [ "Yoda", "" ], [ "Chewbacca", "" ], %w[Lando Calrissian],
      [ "R2-D2", "" ], [ "C-3PO", "" ]
    ]
  },
  {
    owner: sue_suspended,
    classification: "unrestricted",
    prefix: "jr",
    characters: [
      %w[Jack Ryan], %w[John Clark], %w[Domingo Chavez], %w[James Greer],
      %w[Cathy Ryan], [ "Mary Pat", "Foley" ], %w[Ed Foley], %w[Robby Jackson],
      %w[Dan Murray], [ "Arnie", "van Damm" ]
    ]
  }
].freeze

def slug_for(*parts)
  parts.reject(&:blank?).join("_").downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
end

FRANCHISES.each do |franchise|
  franchise[:characters].each do |first, last|
    # full_name uniqueness is global (not scoped per owner), so look up by
    # name alone and reassign ownership if a person with this name already
    # exists under someone else.
    person = Person.find_or_initialize_by(first_name: first, last_name: last.presence)
    person.user = franchise[:owner]
    person.classification = franchise[:classification]
    person.save!

    attach_seed_image(person, :image, "#{franchise[:prefix]}_#{slug_for(first, last)}")

    events_needed = 3 - person.events.count
    events_needed.times do
      event_type = EventType.all.sample
      event = Event.new(
        title:          "#{person.full_name} - #{event_type.name} (#{SecureRandom.hex(3)})",
        description:    "#{event_type.name} event for #{person.full_name}",
        day:            rand(1..28),
        month:          rand(1..12),
        year:           rand(1975..2026),
        event_type:     event_type,
        user:           franchise[:owner],
        classification: franchise[:classification]
      )
      event.people << person
      event.save!
    end
  end
end
