# db/seeds/cookbook.rb

# Cookbook reference data — the starting Cuisines, Food Types and Languages.
# Loaded by db/seeds.rb; also safe to run on its own against an existing
# database (bin/rails runner db/seeds/cookbook.rb), since every row is
# find_or_create_by! on its name. The PROD checklist copy of this list lives
# in docs/reference-data/cookbook/.

[
  [ "Argentinian", "🇦🇷", "Recipes from Argentina" ],
  [ "Australian",  "🇦🇺", "Recipes from Australia" ],
  [ "Dutch",       "🇳🇱", "Recipes from the Netherlands" ],
  [ "Filipino",    "🇵🇭", "Recipes from the Philippines" ],
  [ "French",      "🇫🇷", "Recipes from France" ],
  [ "German",      "🇩🇪", "Recipes from Germany" ],
  [ "Greek",       "🇬🇷", "Recipes from Greece" ],
  [ "Indian",      "🇮🇳", "Recipes from India" ],
  [ "Italian",     "🇮🇹", "Recipes from Italy" ],
  [ "Japanese",    "🇯🇵", "Recipes from Japan" ],
  [ "Malaysian",   "🇲🇾", "Recipes from Malaysia" ],
  [ "Mexican",     "🇲🇽", "Recipes from Mexico" ],
  [ "Portuguese",  "🇵🇹", "Recipes from Portugal" ],
  [ "Spanish",     "🇪🇸", "Recipes from Spain" ],
  [ "Swedish",     "🇸🇪", "Recipes from Sweden" ],
  [ "Thai",        "🇹🇭", "Recipes from Thailand" ],
  [ "Turkish",     "🇹🇷", "Recipes from Turkey" ],
  [ "Vietnamese",  "🇻🇳", "Recipes from Vietnam" ]
].each do |name, flag, description|
  Cuisine.find_or_create_by!(name: name) { |c| c.flag = flag; c.description = description }
end

[
  [ "Appetizers", "sandwich",    "Starters, snacks and small bites" ],
  [ "Barbecue",   "flame",       "Food cooked on the grill" ],
  [ "Bread",      "wheat",       "Loaves, buns and flatbreads" ],
  [ "Christmas",  "tree-pine",   "Festive food for the Christmas table" ],
  [ "Desserts",   "cake-slice",  "Cakes, puddings and other sweet things" ],
  [ "Drinks",     "wine",        "Cocktails, punches and other drinks" ],
  [ "Fish",       "fish",        "Fish and seafood dishes" ],
  [ "Fruit",      "apple",       "Dishes built around fruit" ],
  [ "Meat",       "beef",        "Beef, pork, lamb and poultry dishes" ],
  [ "Mince",      "hamburger",   "Dishes made with minced meat" ],
  [ "Pasta",      "cooking-pot", "Pasta and noodle dishes" ],
  [ "Pies",       "croissant",   "Sweet and savoury pies and pastries" ],
  [ "Soup",       "soup",        "Hot and cold soups" ],
  [ "Vegetarian", "leafy-green", "Dishes without meat or fish" ]
].each do |name, icon, description|
  FoodType.find_or_create_by!(name: name) { |f| f.icon = icon; f.description = description }
end

[
  [ "English", "en", "🇬🇧" ],
  [ "French",  "fr", "🇫🇷" ],
  [ "German",  "de", "🇩🇪" ],
  [ "Spanish", "es", "🇪🇸" ],
  [ "Swedish", "sv", "🇸🇪" ]
].each do |name, code, flag|
  Language.find_or_create_by!(name: name) { |l| l.code = code; l.flag = flag }
end
