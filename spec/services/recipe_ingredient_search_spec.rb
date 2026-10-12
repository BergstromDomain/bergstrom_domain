# spec/services/recipe_ingredient_search_spec.rb

require "rails_helper"

RSpec.describe RecipeIngredientSearch do
  def recipe_with(title, *sections)
    attributes = sections.each_with_index.to_h do |names, s|
      [ s.to_s, { ingredients_attributes: names.each_with_index.to_h { |name, i| [ i.to_s, { quantity: "1", name: name } ] } } ]
    end
    create(:recipe, :published, :unrestricted, title: title, ingredient_sections_attributes: attributes)
  end

  def search(*terms, scope: Recipe.all)
    described_class.new(scope: scope, terms: terms)
  end

  let!(:creamy_chicken) { recipe_with("Creamy Chicken", [ "Chicken breast", "Garlic cloves" ], [ "Double cream" ]) }
  let!(:roast_chicken)  { recipe_with("Roast Chicken", [ "Whole chicken", "Garlic" ]) }
  let!(:chicken_salad)  { recipe_with("Chicken Salad", [ "Chicken thigh", "Lettuce" ]) }
  let!(:pea_soup)       { recipe_with("Pea Soup", [ "Yellow peas", "Onion" ]) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Finds recipes containing every ingredient" do
      expect(search("Chicken", "Garlic", "Cream").recipes).to contain_exactly(creamy_chicken)
    end

    it "Counts the recipes left after each ingredient" do
      expect(search("Chicken", "Garlic", "Cream").steps).to eq([ [ "Chicken", 3 ], [ "Garlic", 2 ], [ "Cream", 1 ] ])
    end

    it "Matches case-insensitively and inside longer names" do
      expect(search("CREAM").recipes).to contain_exactly(creamy_chicken)
    end

    it "Lists a recipe's matching ingredient names in recipe order" do
      result = search("garlic", "cream", "chicken")
      recipe = result.recipes.includes(ingredient_sections: :ingredients).find(creamy_chicken.id)

      expect(result.matched_names(recipe)).to eq([ "Chicken breast", "Garlic cloves", "Double cream" ])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Finds nothing when one ingredient is in no recipe" do
      expect(search("Chicken", "Saffron").recipes).to be_empty
      expect(search("Chicken", "Saffron").steps).to eq([ [ "Chicken", 3 ], [ "Saffron", 0 ] ])
    end

    it "Never returns recipes outside the given scope" do
      expect(search("Chicken", scope: Recipe.where.not(id: roast_chicken.id)).recipes)
        .to contain_exactly(creamy_chicken, chicken_salad)
    end

    it "Treats LIKE wildcards as plain characters" do
      expect(search("%").recipes).to be_empty
      expect(search("_").recipes).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Matches a plural against a singular ingredient name" do
      tomato = recipe_with("Salsa", [ "Tomato", "Egg" ])

      expect(search("Tomatoes").recipes).to contain_exactly(tomato)
      expect(search("eggs").recipes).to contain_exactly(tomato)
    end

    it "Matches Swedish ingredient names whatever their case" do
      kladdkaka = recipe_with("Kladdkaka", [ "Grädde", "Ägg" ])

      expect(search("GRÄDDE", "ägg").recipes).to contain_exactly(kladdkaka)
    end

    it "Splits comma-separated entries into separate ingredients" do
      expect(search("chicken, garlic").terms).to eq([ "chicken", "garlic" ])
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Has no recipes and no steps without ingredients" do
      result = search("", "  ")

      expect(result.terms).to be_empty
      expect(result.steps).to be_empty
      expect(result.recipes).to be_empty
    end

    it "Drops repeated ingredients, keeping the first spelling" do
      expect(search("Garlic", " garlic ", "Chicken").terms).to eq([ "Garlic", "Chicken" ])
    end

    it "Does not trim short words to almost nothing" do
      expect(search("Os").recipes).to be_empty
    end

    it "Uses only the first #{described_class::MAX_TERMS} ingredients" do
      terms = Array.new(described_class::MAX_TERMS + 2) { |i| "term#{i}" }
      expect(search(*terms).terms.size).to eq(described_class::MAX_TERMS)
    end
  end
end
