# spec/services/recipe_export_service_spec.rb

require "rails_helper"

RSpec.describe RecipeExportService do
  let(:chef)     { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }
  let(:swedish)  { create(:cuisine, name: "Swedish") }
  let(:italian)  { create(:cuisine, name: "Italian") }
  let(:pasta)    { create(:food_type, name: "Pasta") }
  let(:mince)    { create(:food_type, name: "Mince Meat") }
  let(:svenska)  { create(:language, name: "Swedish", code: "sv") }

  def rows_for(*recipes)
    CSV.parse(described_class.new(recipes).generate_csv, headers: true)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Returns a CSV string with the header row" do
      expect(described_class.new([]).generate_csv.lines.first.chomp.split(",")).to eq(described_class::HEADERS)
    end

    it "Includes one row per recipe with the expected columns" do
      recipe = create(:recipe, :published, user: chef, title: "Swedish Lasagna", language: svenska,
        cuisines: [ swedish, italian ], food_types: [ pasta, mince ], serves: 6, cook_time: "1 hour",
        description: "A family favourite", body: "## Layer\n\nLayer the sauce and pasta.",
        ingredient_sections_attributes: { "0" => { ingredients_attributes: {
          "0" => { quantity: "500", measurement: "g", name: "Minced beef" } } } })

      row = rows_for(recipe).first

      expect(row["Title"]).to eq("Swedish Lasagna")
      expect(row["Cuisine"]).to eq("Swedish · Italian")
      expect(row["Food Type"]).to eq("Pasta · Mince Meat")
      expect(row["Language"]).to eq("Swedish")
      expect(row["Chef"]).to eq("Ada Lovelace")
      expect(row["Created"]).to eq(recipe.created_at.strftime("%d-%b-%Y"))
      expect(row["Published"]).to eq("Yes")
      expect(row["Serves"]).to eq("6")
      expect(row["Makes"]).to be_nil
      expect(row["Cook Time"]).to eq("1 hour")
      expect(row["Description"]).to eq("A family favourite")
      expect(row["Ingredients"]).to eq("500 g Minced beef")
      expect(row["Method (Markdown)"]).to eq("## Layer\n\nLayer the sauce and pasta.")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns just the header row for an empty recipe list" do
      expect(rows_for.length).to eq(0)
    end

    it "Marks a draft as not published" do
      expect(rows_for(create(:recipe, user: chef)).first["Published"]).to eq("No")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Writes one line per ingredient, with each section heading on its own line above its ingredients" do
      recipe = create(:recipe, user: chef, ingredient_sections_attributes: {
        "0" => { heading: "Sauce", ingredients_attributes: {
          "0" => { quantity: "1", measurement: "tbsp", name: "Butter", comment: "softened" },
          "1" => { quantity: "2", name: "Garlic cloves" } } },
        "1" => { heading: "Topping", ingredients_attributes: {
          "0" => { quantity: "100", measurement: "g", name: "Parmesan" } } }
      })

      expect(rows_for(recipe).first["Ingredients"]).to eq(
        "Sauce\n1 tbsp Butter, softened\n2 Garlic cloves\nTopping\n100 g Parmesan"
      )
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Leaves Ingredients and Method blank for a recipe without them" do
      row = rows_for(create(:recipe, user: chef, body: nil)).first

      expect(row["Ingredients"]).to be_nil
      expect(row["Method (Markdown)"]).to be_nil
    end

    it "Keeps commas and quotes inside a cell" do
      recipe = create(:recipe, user: chef, title: 'Mum\'s "Best", Ever Stew')
      expect(rows_for(recipe).first["Title"]).to eq('Mum\'s "Best", Ever Stew')
    end
  end
end
