# app/models/recipe_food_type.rb

# One of a Recipe's (at most two) Food Types; `position` 0 is the primary one.
# Built by Recipe#food_types= in the order chosen.
class RecipeFoodType < ApplicationRecord
  belongs_to :recipe
  belongs_to :food_type
end
