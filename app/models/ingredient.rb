# app/models/ingredient.rb
class Ingredient < ApplicationRecord
  belongs_to :ingredient_section

  validates :quantity, :name, presence: true
end
