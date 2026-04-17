# db/seeds.rb

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

# ── People ──────────────────────────────────────────────────────────────────
people = {
  hetfield: Person.find_or_create_by!(first_name: "James",  middle_name: nil,    last_name: "Hetfield"),
  ulrich:   Person.find_or_create_by!(first_name: "Lars",   middle_name: nil,    last_name: "Ulrich"),
  hammett:  Person.find_or_create_by!(first_name: "Kirk",   middle_name: nil,    last_name: "Hammett"),
  trujillo: Person.find_or_create_by!(first_name: "Robert", middle_name: nil,    last_name: "Trujillo")
}

# ── Events ──────────────────────────────────────────────────────────────────
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
    event_type: event_types[:music]
  )

  event.people << people[:hetfield] unless event.people.include?(people[:hetfield])
  event.save!
end
