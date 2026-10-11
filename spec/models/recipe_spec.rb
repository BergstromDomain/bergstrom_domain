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
    it { is_expected.to have_db_column(:cuisine_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:food_type_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:language_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:cuisine).without_validating_presence }
    it { is_expected.to belong_to(:food_type).without_validating_presence }
    it { is_expected.to belong_to(:language).without_validating_presence }
    it { is_expected.to have_one_attached(:recipe_image) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
    it { is_expected.to have_many(:ingredient_sections).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:ingredient_sections).allow_destroy(true) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    it { is_expected.to validate_presence_of(:cuisine) }
    it { is_expected.to validate_presence_of(:food_type) }
    it { is_expected.to validate_presence_of(:language) }

    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid as a draft with a title, Cuisine, Food Type and Language" do
        expect(build(:recipe, body: nil, published_at: nil)).to be_valid
      end

      it "is valid when published with a body" do
        expect(build(:recipe, :published)).to be_valid
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
        recipe = build(:recipe, cuisine: nil, food_type: nil, language: nil)
        expect(recipe).not_to be_valid
        expect(recipe.errors[:cuisine]).to include("can't be blank")
        expect(recipe.errors[:food_type]).to include("can't be blank")
        expect(recipe.errors[:language]).to include("can't be blank")
      end

      it "is invalid when published without a body" do
        recipe = build(:recipe, :published, body: "")
        expect(recipe).not_to be_valid
        expect(recipe.errors[:body]).to include("can't be blank")
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
  describe "#to_toast_label" do
    it "uses the title" do
      expect(build(:recipe, title: "Meatballs").to_toast_label).to eq("Meatballs")
    end
  end
end
