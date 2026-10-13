# app/models/ingredient_section.rb

# One ingredient list on a Recipe, optionally headed ("Meat sauce"). Lists
# and their rows keep the order they were entered in (`position`, set by
# Recipe#assign_ingredient_positions).
class IngredientSection < ApplicationRecord
  belongs_to :recipe

  has_many :ingredients, -> { order(:position) }, dependent: :destroy, inverse_of: :ingredient_section
  accepts_nested_attributes_for :ingredients, allow_destroy: true,
    reject_if: ->(attrs) { attrs.slice("quantity", "measurement", "name", "comment").values.all?(&:blank?) }
end
