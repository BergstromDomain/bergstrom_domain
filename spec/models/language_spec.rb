# spec/models/language_spec.rb
require "rails_helper"

RSpec.describe Language, type: :model do
  subject { build(:language) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:code).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:flag).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:recipes).dependent(:restrict_with_error) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with all required fields" do
        expect(build(:language, name: "Swedish", code: "sv", flag: "🇸🇪")).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when name is blank" do
        language = build(:language, name: "")
        expect(language).not_to be_valid
        expect(language.errors[:name]).to include("can't be blank")
      end

      it "is invalid when name is a duplicate (different case)" do
        create(:language, name: "Swedish", code: "sv")
        language = build(:language, name: "swedish", code: "se")
        expect(language).not_to be_valid
        expect(language.errors[:name]).to include("has already been taken")
      end

      it "is invalid when code is blank" do
        language = build(:language, code: "")
        expect(language).not_to be_valid
        expect(language.errors[:code]).to include("can't be blank")
      end

      it "is invalid when code is not two letters" do
        %w[s swe s1 12].each do |code|
          language = build(:language, code: code)
          expect(language).not_to be_valid, "expected #{code.inspect} to be rejected"
          expect(language.errors[:code]).to include("must be two letters, e.g. sv")
        end
      end

      it "is invalid when code is a duplicate" do
        create(:language, name: "Swedish", code: "sv")
        language = build(:language, name: "Svenska", code: "sv")
        expect(language).not_to be_valid
        expect(language.errors[:code]).to include("has already been taken")
      end

      it "is invalid when flag is blank" do
        language = build(:language, flag: "")
        expect(language).not_to be_valid
        expect(language.errors[:flag]).to include("can't be blank")
      end

      it "is invalid when flag is plain text rather than an emoji" do
        language = build(:language, flag: "GB")
        expect(language).not_to be_valid
        expect(language.errors[:flag]).to include("must be a single emoji, e.g. 🇸🇪")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "stores an upper-case code as lower case" do
        language = create(:language, code: "SV")
        expect(language.code).to eq("sv")
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "treats a code differing only in case as a duplicate" do
        create(:language, name: "Swedish", code: "sv")
        language = build(:language, name: "Svenska", code: "SV")
        expect(language).not_to be_valid
        expect(language.errors[:code]).to include("has already been taken")
      end

      it "uses its name as the toast label" do
        expect(build(:language, name: "Swedish").to_toast_label).to eq("Swedish")
      end
    end
  end
end
