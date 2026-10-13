# app/models/recipe_cuisine.rb

# One of a Recipe's (at most two) Cuisines; `position` 0 is the primary one.
# Built by Recipe#cuisines= in the order chosen.
class RecipeCuisine < ApplicationRecord
  belongs_to :recipe
  belongs_to :cuisine
end
