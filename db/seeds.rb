# db/seeds.rb

# ── EventTypes ───────────────────────────────────────────────────────────
event_types_data = [
  {
    name:        "Birthday",
    description: "Birth anniversaries and birthday celebrations.",
    icon:        "cake"
  },
  {
    name:        "Education",
    description: "School, university, graduation, and other learning milestones.",
    icon:        "graduation-cap"
  },
  {
    name:        "Work",
    description: "Career milestones, job changes, promotions, and professional achievements.",
    icon:        "briefcase"
  },
  {
    name:        "Sport",
    description: "Sporting achievements, competitions, and fitness milestones.",
    icon:        "dumbbell"
  },
  {
    name:        "Wedding",
    description: "Marriages, civil ceremonies, and anniversary celebrations.",
    icon:        "heart"
  },
  {
    name:        "Music",
    description: "Album releases, concerts, tours, and musical milestones.",
    icon:        "music"
  }
]

event_types_data.each do |attrs|
  EventType.find_or_create_by!(name: attrs[:name]) do |et|
    et.description = attrs[:description]
    et.icon        = attrs[:icon]
  end
end

puts "Seeded #{EventType.count} event types."

# ── People ───────────────────────────────────────────────────────────────
people = [
  { first_name: "James",  middle_name: "Alan",   last_name: "Hetfield",
    description: "Vocalist and rhythm guitarist. Co-founder of Metallica.",
    thumbnail_image: nil, full_image: nil },
  { first_name: "Lars",   middle_name: nil,       last_name: "Ulrich",
    description: "Drummer and co-founder of Metallica.",
    thumbnail_image: nil, full_image: nil },
  { first_name: "Kirk",   middle_name: "Lee",     last_name: "Hammett",
    description: "Lead guitarist of Metallica since 1983.",
    thumbnail_image: nil, full_image: nil },
  { first_name: "Robert", middle_name: "George",  last_name: "Trujillo",
    description: "Bassist of Metallica since 2003.",
    thumbnail_image: nil, full_image: nil }
]

people.each do |attrs|
  Person.find_or_create_by!(
    first_name:  attrs[:first_name],
    middle_name: attrs[:middle_name],
    last_name:   attrs[:last_name]
  ) do |p|
    p.description = attrs[:description]
  end
end

puts "Seeded #{Person.count} people."

# ── Events (Metallica albums) ─────────────────────────────────────────────
metallica_albums = [
  { title: "Kill 'Em All",                  day: 25, month: 7,  year: 1983 },
  { title: "Ride the Lightning",            day: 27, month: 7,  year: 1984 },
  { title: "Master of Puppets",             day: 3,  month: 3,  year: 1986 },
  { title: "...And Justice for All",        day: 25, month: 8,  year: 1988 },
  { title: "Metallica (Black Album)",       day: 12, month: 8,  year: 1991 },
  { title: "Load",                          day: 4,  month: 6,  year: 1996 },
  { title: "Reload",                        day: 18, month: 11, year: 1997 },
  { title: "St. Anger",                     day: 5,  month: 6,  year: 2003 },
  { title: "Death Magnetic",                day: 12, month: 9,  year: 2008 },
  { title: "Hardwired... to Self-Destruct", day: 18, month: 11, year: 2016 },
  { title: "72 Seasons",                    day: 14, month: 4,  year: 2023 }
]

metallica_albums.each do |attrs|
  Event.find_or_create_by!(title: attrs[:title]) do |e|
    e.day         = attrs[:day]
    e.month       = attrs[:month]
    e.year        = attrs[:year]
    e.description = "Metallica studio album released on #{attrs[:day]}/#{attrs[:month]}/#{attrs[:year]}."
  end
end

puts "Seeded #{Event.count} events."
