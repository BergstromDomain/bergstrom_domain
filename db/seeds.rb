# db/seeds.rb

# ── People ────────────────────────────────────────────────────────────────
puts "Seeding people..."

people = [
  {
    first_name:      "James",
    middle_name:     "Alan",
    last_name:       "Hetfield",
    description:     "Vocalist and rhythm guitarist, co-founder of Metallica.",
    thumbnail_image: "people/thumbnails/james_hetfield_thumb.jpg",
    full_image:      "people/full/james_hetfield.jpg"
  },
  {
    first_name:      "Lars",
    middle_name:     nil,
    last_name:       "Ulrich",
    description:     "Drummer and co-founder of Metallica.",
    thumbnail_image: "people/thumbnails/lars_ulrich_thumb.jpg",
    full_image:      "people/full/lars_ulrich.jpg"
  },
  {
    first_name:      "Kirk",
    middle_name:     "Lee",
    last_name:       "Hammett",
    description:     "Lead guitarist of Metallica.",
    thumbnail_image: "people/thumbnails/kirk_hammett_thumb.jpg",
    full_image:      "people/full/kirk_hammett.jpg"
  },
  {
    first_name:      "Robert",
    middle_name:     "George",
    last_name:       "Trujillo",
    description:     "Bassist of Metallica.",
    thumbnail_image: "people/thumbnails/robert_trujillo_thumb.jpg",
    full_image:      "people/full/robert_trujillo.jpg"
  }
]

people.each do |attrs|
  Person.find_or_create_by!(
    first_name:  attrs[:first_name],
    middle_name: attrs[:middle_name],
    last_name:   attrs[:last_name]
  ) do |p|
    p.description     = attrs[:description]
    p.thumbnail_image = attrs[:thumbnail_image]
    p.full_image      = attrs[:full_image]
  end
end

puts "Seeded #{Person.count} people."

# ── Events ────────────────────────────────────────────────────────────────
puts "Seeding events..."

metallica_albums = [
  { title: "Kill 'Em All",                   day: 25, month: 7,  year: 1983, description: "Metallica's debut studio album. Originally titled 'Metal Up Your Ass'." },
  { title: "Ride the Lightning",             day: 27, month: 7,  year: 1984, description: "Second studio album. A step forward in complexity and heaviness." },
  { title: "Master of Puppets",              day: 3,  month: 3,  year: 1986, description: "Widely considered one of the greatest heavy metal albums ever made." },
  { title: "...And Justice for All",         day: 5,  month: 9,  year: 1988, description: "Fourth studio album, notable for its extremely dry bass sound." },
  { title: "Metallica (The Black Album)",    day: 12, month: 8,  year: 1991, description: "The self-titled 'Black Album'. One of the best-selling albums of all time." },
  { title: "Load",                           day: 4,  month: 6,  year: 1996, description: "Sixth studio album, marking a shift toward hard rock and blues influences." },
  { title: "Reload",                         day: 18, month: 11, year: 1997, description: "Companion album to Load, featuring songs written during the same sessions." },
  { title: "St. Anger",                      day: 5,  month: 6,  year: 2003, description: "Eighth studio album, recorded during a turbulent period for the band." },
  { title: "Death Magnetic",                 day: 12, month: 9,  year: 2008, description: "Ninth studio album, a return to the thrash metal sound of their earlier work." },
  { title: "Hardwired... to Self-Destruct",  day: 18, month: 11, year: 2016, description: "Tenth studio album. A double album released after an eight-year hiatus." },
  { title: "72 Seasons",                     day: 14, month: 4,  year: 2023, description: "Eleventh studio album. The title refers to the first 18 years of one's life." }
]

metallica_albums.each do |attrs|
  Event.find_or_create_by!(title: attrs[:title]) do |e|
    e.description = attrs[:description]
    e.day         = attrs[:day]
    e.month       = attrs[:month]
    e.year        = attrs[:year]
  end
end

puts "Seeded #{Event.count} events."
puts "Done."
