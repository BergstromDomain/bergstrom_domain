# spec/services/recipe_filter_spec.rb

require "rails_helper"

RSpec.describe RecipeFilter do
  let(:chef)    { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }
  let(:swedish) { create(:cuisine, name: "Swedish") }
  let(:italian) { create(:cuisine, name: "Italian") }
  let(:pasta)   { create(:food_type, name: "Pasta", icon: "cooking-pot") }
  let(:english) { create(:language, name: "English", code: "en") }

  def lasagna(**attrs)
    create(:recipe, :published, user: chef, title: "Swedish Lasagna", cuisines: [ swedish, italian ],
      food_types: [ pasta ], language: english, serves: 4, cook_time: "1 hour",
      ingredient_sections_attributes: { "0" => { ingredients_attributes: {
        "0" => { quantity: "500", measurement: "g", name: "Minced beef" },
        "1" => { quantity: "2", name: "Garlic cloves" }
      } } }, **attrs)
  end

  def matches?(query, recipe)
    ast = Jql::Parser.parse(query)
    described_class::EVALUATOR.validate!(ast)
    described_class::EVALUATOR.matches?(ast, described_class.attributes_for(recipe))
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    describe ".attributes_for" do
      it "Gives every field, with Cuisines, Food Types and ingredients as lists" do
        recipe = lasagna
        create(:comment, commentable: recipe, user: chef)
        attrs = described_class.attributes_for(recipe.reload)

        expect(described_class::FIELD_SCHEMA.keys.index_with { |field| attrs[field] }).to eq(
          cuisine:     [ "Swedish", "Italian" ],
          food_type:   [ "Pasta" ],
          language:    "English",
          title:       "Swedish Lasagna",
          chef:        "Ada Lovelace",
          cook_time:   "1 hour",
          created:     recipe.created_at,
          portions:    4,
          serves:      4,
          makes:       nil,
          comments:    1,
          reactions:   nil,
          published:   true,
          ingredients: [ "Minced beef", "Garlic cloves" ]
        )
      end
    end

    describe "SQL queries" do
      it "Matches either Cuisine, and any ingredient by CONTAINS" do
        recipe = lasagna
        expect(matches?('cuisine = "Italian" AND ingredients CONTAINS "garlic"', recipe)).to be true
        expect(matches?('cuisine = "French" OR ingredients CONTAINS "cream"', recipe)).to be false
      end
    end

    describe ".basic_ast" do
      it "Returns nil (no filter) when every argument is blank" do
        expect(described_class.basic_ast).to be_nil
      end

      it "Combines Cuisine, Food Type, Language, Chef and Published with AND" do
        recipe = lasagna
        ast = described_class.basic_ast(cuisine: "Italian", food_type: "Pasta", language: "English",
          chef_name: "Ada Lovelace", published: "true")
        attrs = described_class.attributes_for(recipe)
        expect(described_class::EVALUATOR.matches?(ast, attrs)).to be true

        other = described_class.basic_ast(cuisine: "Italian", language: "Swedish")
        expect(described_class::EVALUATOR.matches?(other, attrs)).to be false
      end

      it "Filters by the Created range boundaries" do
        recipe = lasagna(created_at: Time.zone.local(2026, 1, 15))
        attrs = described_class.attributes_for(recipe)
        january = described_class.basic_ast(created_range: Date.new(2026, 1, 1)..Date.new(2026, 1, 31))
        february = described_class.basic_ast(created_range: Date.new(2026, 2, 1)..Date.new(2026, 2, 28))

        expect(described_class::EVALUATOR.matches?(january, attrs)).to be true
        expect(described_class::EVALUATOR.matches?(february, attrs)).to be false
      end
    end

    describe ".sort" do
      it "Sorts by Title ascending and descending" do
        a = create(:recipe, title: "Apple Pie")
        b = create(:recipe, title: "Banana Bread")
        expect(described_class.sort([ b, a ], "title", "asc")).to eq([ a, b ])
        expect(described_class.sort([ a, b ], "title", "desc")).to eq([ b, a ])
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects a field that doesn't exist, such as Chronicle's 'smiles'" do
      expect { described_class::EVALUATOR.validate!(Jql::Parser.parse("smiles > 3")) }
        .to raise_error(Jql::ParseError, /smiles/)
    end

    it "Ignores a blank Basic filter rather than matching an empty value" do
      expect(described_class.basic_ast(cuisine: "", chef_name: nil)).to be_nil
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Sorts by the primary Cuisine" do
      swedish_first = create(:recipe, cuisines: [ swedish, italian ])
      italian_only  = create(:recipe, cuisines: [ italian ])
      expect(described_class.sort([ swedish_first, italian_only ], "cuisine", "asc"))
        .to eq([ italian_only, swedish_first ])
    end

    it "Sorts by Reactions using the computed score" do
      low  = create(:recipe)
      high = create(:recipe)
      create(:like, likeable: low,  user: create(:user), face: "angry")
      create(:like, likeable: high, user: create(:user), face: "grinning")
      expect(described_class.sort([ low, high ], "reactions", "desc").first).to eq(high)
    end

    it "Preloads only the associations a set of fields needs" do
      recipe = lasagna
      recipes = Recipe.where(id: recipe.id).to_a
      described_class.preload(recipes, %i[ingredients title])

      expect(recipes.first.association(:ingredient_sections)).to be_loaded
      expect(recipes.first.association(:language)).not_to be_loaded
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sorts recipes with no reactions last, whichever the direction" do
      none  = create(:recipe)
      rated = create(:recipe)
      create(:like, likeable: rated, user: create(:user), face: "neutral")
      expect(described_class.sort([ none, rated ], "reactions", "asc")).to eq([ rated, none ])
      expect(described_class.sort([ none, rated ], "reactions", "desc")).to eq([ rated, none ])
    end

    it "Never matches an ingredient query on a recipe with no ingredients" do
      expect(matches?('ingredients CONTAINS "garlic"', create(:recipe))).to be false
    end
  end
end
