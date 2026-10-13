# spec/models/recipe_spec.rb
require "rails_helper"

RSpec.describe Recipe, type: :model do
  subject { build(:recipe) }

  let(:owner) { create(:user, :content_creator) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:body).of_type(:text) }
    it { is_expected.to have_db_column(:format).of_type(:string).with_options(null: false, default: "formatted") }
    it { is_expected.to have_db_column(:serves).of_type(:integer) }
    it { is_expected.to have_db_column(:makes).of_type(:integer) }
    it { is_expected.to have_db_column(:cook_time).of_type(:string) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "contacts") }
    it { is_expected.to have_db_column(:published_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:comments_count).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.not_to have_db_column(:cuisine_id) }
    it { is_expected.not_to have_db_column(:food_type_id) }
    it { is_expected.to have_db_column(:language_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:recipe_cuisines).dependent(:destroy) }
    it { is_expected.to have_many(:cuisines).through(:recipe_cuisines) }
    it { is_expected.to have_many(:recipe_food_types).dependent(:destroy) }
    it { is_expected.to have_many(:food_types).through(:recipe_food_types) }
    it { is_expected.to belong_to(:language).without_validating_presence }
    it { is_expected.to have_one_attached(:recipe_image) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:ingredient_sections).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:ingredient_sections).allow_destroy(true) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    it { is_expected.to validate_presence_of(:language) }

    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid as a draft with a title, Cuisine, Food Type and Language" do
        expect(build(:recipe, body: nil, published_at: nil)).to be_valid
      end

      it "is valid when published with a Method and an ingredient" do
        expect(build(:recipe, :published)).to be_valid
      end

      it "is valid with two Cuisines and two Food Types" do
        recipe = build(:recipe, cuisines: create_list(:cuisine, 2), food_types: create_list(:food_type, 2))
        expect(recipe).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when title is blank" do
        recipe = build(:recipe, title: "")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:title]).to include("can't be blank")
      end

      it "is invalid when the same owner reuses a title (different case)" do
        create(:recipe, user: owner, title: "Meatballs")
        recipe = build(:recipe, user: owner, title: "meatballs")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:title]).to include("has already been taken")
      end

      it "is invalid as a draft without a Cuisine, Food Type or Language" do
        recipe = build(:recipe, cuisines: [], food_types: [], language: nil)
        expect(recipe).not_to be_valid
        expect(recipe.errors[:cuisines]).to include("can't be blank")
        expect(recipe.errors[:food_types]).to include("can't be blank")
        expect(recipe.errors[:language]).to include("can't be blank")
        expect(recipe.errors.full_messages).to include("Cuisine can't be blank", "Food Type can't be blank")
      end

      it "is invalid with three Cuisines or three Food Types" do
        recipe = build(:recipe, cuisines: create_list(:cuisine, 3), food_types: create_list(:food_type, 3))
        expect(recipe).not_to be_valid
        expect(recipe.errors[:cuisines]).to include("can have at most 2")
        expect(recipe.errors[:food_types]).to include("can have at most 2")
      end

      it "is invalid when published without a body" do
        recipe = build(:recipe, :published, body: "")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:body]).to include("can't be blank")
        expect(recipe.errors.full_messages).to include("Method can't be blank")
      end

      it "is invalid when published without an ingredient" do
        recipe = build(:recipe, published_at: Time.current)
        expect(recipe).not_to be_valid
        expect(recipe.errors[:base]).to include("Add at least one ingredient before publishing")
      end

      it "is invalid when Serves or Makes is zero or negative" do
        recipe = build(:recipe, serves: 0, makes: -1)
        expect(recipe).not_to be_valid
        expect(recipe.errors[:serves]).to include("must be greater than 0")
        expect(recipe.errors[:makes]).to include("must be greater than 0")
      end

      it "is invalid when Serves is not a whole number" do
        recipe = build(:recipe, serves: "2.5")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:serves]).to include("must be an integer")
      end

      it "is invalid with a recipe image that isn't JPEG, PNG or WebP" do
        recipe = build(:recipe)
        recipe.recipe_image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
          filename: "test_image.gif", content_type: "image/gif")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:recipe_image]).to include("must be a JPEG, PNG, or WebP")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "lets two different owners use the same title" do
        create(:recipe, user: owner, title: "Meatballs")
        expect(build(:recipe, title: "Meatballs")).to be_valid
      end

      it "gives the second owner's recipe a distinct slug" do
        first  = create(:recipe, user: owner, title: "Meatballs")
        second = create(:recipe, title: "Meatballs")
        expect(second.slug).not_to eq(first.slug)
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "allows both Serves and Makes to be blank" do
        expect(build(:recipe, serves: nil, makes: nil)).to be_valid
      end

      it "allows a draft with no ingredients" do
        expect(build(:recipe, published_at: nil).ingredient_sections).to be_empty
        expect(build(:recipe, published_at: nil)).to be_valid
      end

      it "counts no ingredient that is marked for destruction" do
        recipe = create(:recipe, :published)
        recipe.ingredient_sections.first.ingredients.each(&:mark_for_destruction)
        expect(recipe).not_to be_valid
        expect(recipe.errors[:base]).to include("Add at least one ingredient before publishing")
      end

      it "counts no ingredient in a list that is marked for destruction" do
        recipe = create(:recipe, :published)
        recipe.ingredient_sections.each(&:mark_for_destruction)
        expect(recipe).not_to be_valid
      end
    end
  end

  # ── Serves / Makes ────────────────────────────────────────────────────────
  describe "#portions" do
    it "uses Makes when it is set, even if Serves is too" do
      expect(build(:recipe, serves: 4, makes: 24).portions).to eq([ "Makes", 24 ])
    end

    it "falls back to Serves when Makes is blank" do
      expect(build(:recipe, serves: 4, makes: nil).portions).to eq([ "Serves", 4 ])
    end

    it "still labels it Serves when both are blank" do
      expect(build(:recipe, serves: nil, makes: nil).portions).to eq([ "Serves", nil ])
    end
  end

  # ── Cuisines / Food Types ─────────────────────────────────────────────────
  describe "Cuisines and Food Types" do
    let(:swedish) { create(:cuisine, name: "Swedish") }
    let(:italian) { create(:cuisine, name: "Italian") }
    let(:pasta)   { create(:food_type, name: "Pasta", icon: "cooking-pot") }
    let(:mince)   { create(:food_type, name: "Mince Meat", icon: "beef") }

    # 1) Happy Path ──────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "keeps them in the order they were chosen, the first being the primary one" do
        recipe = create(:recipe, cuisines: [ italian, swedish ], food_types: [ mince, pasta ])
        expect(recipe.reload.cuisines).to eq([ italian, swedish ])
        expect(recipe.food_types).to eq([ mince, pasta ])
        expect(recipe.cuisine_ids).to eq([ italian.id, swedish.id ])
      end

      it "assigns them from the form's ids, in order" do
        recipe = create(:recipe, cuisines: [ swedish ])
        recipe.update!(cuisine_ids: [ "", italian.id.to_s, swedish.id.to_s ], food_type_ids: [ pasta.id.to_s, "" ])
        expect(recipe.reload.cuisines).to eq([ italian, swedish ])
        expect(recipe.food_types).to eq([ pasta ])
      end
    end

    # 2) Negative Path ───────────────────────────────────────────────────────
    describe "Negative Path" do
      it "leaves the saved choices alone when an update fails" do
        recipe = create(:recipe, cuisines: [ swedish ])
        expect(recipe.update(cuisine_ids: [ "" ])).to be(false)
        expect(recipe.reload.cuisines).to eq([ swedish ])
      end
    end

    # 3) Alternative Paths ───────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "swaps the primary and the second one" do
        recipe = create(:recipe, cuisines: [ swedish, italian ])
        recipe.update!(cuisine_ids: [ italian.id, swedish.id ])
        expect(recipe.reload.cuisines).to eq([ italian, swedish ])
      end

      it "drops the second one" do
        recipe = create(:recipe, cuisines: [ swedish, italian ])
        recipe.update!(cuisine_ids: [ swedish.id ])
        expect(recipe.reload.cuisines).to eq([ swedish ])
      end
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "ignores the same Cuisine chosen twice" do
        recipe = create(:recipe, cuisine_ids: [ swedish.id, swedish.id ])
        expect(recipe.reload.cuisines).to eq([ swedish ])
      end

      it "ignores an id that doesn't exist" do
        recipe = create(:recipe, cuisine_ids: [ swedish.id, 0 ])
        expect(recipe.reload.cuisines).to eq([ swedish ])
      end
    end
  end

  # ── Visibility ────────────────────────────────────────────────────────────
  describe "Visibility" do
    let(:uno) { create(:user) }

    let!(:public_recipe)  { create(:recipe, :published, :unrestricted, user: owner) }
    let!(:private_recipe) { create(:recipe, :published, :restricted, user: owner) }
    let!(:draft_recipe)   { create(:recipe, :unrestricted, user: owner) }
    let!(:deleted_recipe) { create(:recipe, :published, :unrestricted, user: owner, deleted_at: Time.current) }

    it "shows guests only published, unrestricted, kept recipes" do
      expect(Recipe.visible_to_visitors).to contain_exactly(public_recipe)
    end

    it "shows the owner their own drafts and restricted recipes, but not deleted ones" do
      expect(Recipe.visible_to_users(owner)).to contain_exactly(public_recipe, private_recipe, draft_recipe)
    end

    it "never shows another user's draft, even an unrestricted one" do
      expect(Recipe.visible_to_users(uno)).to contain_exactly(public_recipe)
    end

    it "shows admins everything except soft-deleted recipes" do
      expect(Recipe.visible_to_admins).to contain_exactly(public_recipe, private_recipe, draft_recipe)
    end
  end

  # ── Ingredients ───────────────────────────────────────────────────────────
  describe "Ingredients" do
    def ingredient(quantity, name, measurement: nil, comment: nil)
      { quantity: quantity, measurement: measurement, name: name, comment: comment }
    end

    # 1) Happy Path ──────────────────────────────────────────────────────────
    it "Saves headed lists and their rows in the order submitted" do
      recipe = create(:recipe, ingredient_sections_attributes: {
        "0" => { heading: "Meat sauce", ingredients_attributes: {
          "0" => ingredient("500", "minced beef", measurement: "g"),
          "1" => ingredient("1", "onion", comment: "finely chopped")
        } },
        "1" => { heading: "White sauce", ingredients_attributes: { "0" => ingredient("5", "milk", measurement: "dl") } }
      })

      sections = recipe.reload.ingredient_sections
      expect(sections.map(&:heading)).to eq([ "Meat sauce", "White sauce" ])
      expect(sections.map(&:position)).to eq([ 0, 1 ])
      expect(sections.first.ingredients.map(&:name)).to eq([ "minced beef", "onion" ])
      expect(sections.first.ingredients.map(&:position)).to eq([ 0, 1 ])
    end

    # 2) Negative Path ───────────────────────────────────────────────────────
    it "Is invalid when a row has an ingredient but no quantity" do
      recipe = build(:recipe, ingredient_sections_attributes: {
        "0" => { ingredients_attributes: { "0" => ingredient("", "salt") } }
      })
      expect(recipe).not_to be_valid
      expect(recipe.errors.full_messages).to include("Quantity can't be blank")
    end

    # 3) Alternative Path ────────────────────────────────────────────────────
    it "Ignores completely blank rows and an empty list with no heading" do
      recipe = create(:recipe, ingredient_sections_attributes: {
        "0" => { heading: "", ingredients_attributes: { "0" => ingredient("", "") } }
      })
      expect(recipe.ingredient_sections).to be_empty
    end

    # 4) Edge Cases ──────────────────────────────────────────────────────────
    it "Keeps free-text quantities exactly as typed" do
      recipe = create(:recipe, ingredient_sections_attributes: {
        "0" => { ingredients_attributes: { "0" => ingredient("½", "lemon"), "1" => ingredient("2–3", "garlic cloves") } }
      })
      expect(recipe.reload.ingredient_sections.first.ingredients.map(&:quantity)).to eq([ "½", "2–3" ])
    end
  end

  # ── Toasts ────────────────────────────────────────────────────────────────
  describe "#purge_at" do
    it "is 30 days after deletion" do
      deleted_at = Time.zone.parse("2026-10-12 10:00")
      expect(build(:recipe, deleted_at: deleted_at).purge_at).to eq(deleted_at + 30.days)
    end

    it "is nil for a recipe that isn't deleted" do
      expect(build(:recipe).purge_at).to be_nil
    end
  end

  describe "#to_toast_label" do
    it "uses the title" do
      expect(build(:recipe, title: "Meatballs").to_toast_label).to eq("Meatballs")
    end
  end
end
