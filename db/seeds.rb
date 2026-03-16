# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Person.destroy_all

people_data = [
  { firstname: "James", lastname: "Hetfield", description: "Lead vocalist and rhythm guitarist of Metallica.", thumbnail_image: "james_hetfield_thumb.jpg", full_image: "james_hetfield.jpg" },
  { firstname: "Lars", lastname: "Ulrich", description: "Drummer and co-founder of Metallica.", thumbnail_image: "lars_ulrich_thumb.jpg", full_image: "lars_ulrich.jpg" },
  { firstname: "Kirk", lastname: "Hammett", description: "Lead guitarist of Metallica.", thumbnail_image: "kirk_hammett_thumb.jpg", full_image: "kirk_hammett.jpg" },
  { firstname: "Robert", lastname: "Trujillo", description: "Bass guitarist of Metallica since 2003.", thumbnail_image: "robert_trujillo_thumb.jpg", full_image: "robert_trujillo.jpg" },
  { firstname: "Cliff", lastname: "Burton", description: "Legendary Metallica bassist who played from 1982–1986.", thumbnail_image: "cliff_burton_thumb.jpg", full_image: "cliff_burton.jpg" }
]

people_data.each do |attrs|
  Person.create!(attrs)
end
