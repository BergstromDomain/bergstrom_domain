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

puts "Seeded #{Person.count} people"
