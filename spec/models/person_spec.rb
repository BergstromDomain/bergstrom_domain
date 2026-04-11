# spec/models/person_spec.rb

require "rails_helper"

RSpec.describe Person, type: :model do
  subject(:person) { build(:person, :james_hetfield) }

  # ── Database columns ─────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:middle_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:thumbnail_image).of_type(:string) }
    it { is_expected.to have_db_column(:full_image).of_type(:string) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }

    context "full_name uniqueness" do
      it "is valid when full_name is unique" do
        create(:person, :james_hetfield)
        lars = build(:person, :lars_ulrich)
        expect(lars).to be_valid
      end

      it "is invalid when full_name already exists" do
        create(:person, :kirk_hammett)
        duplicate = build(:person, :kirk_hammett)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:base]).to include("Full name has already been taken")
      end

      it "treats nil middle name the same as blank" do
        create(:person, :lars_ulrich)
        duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "Ulrich")
        expect(duplicate).not_to be_valid
      end
    end
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:event_people) }
    it { is_expected.to have_many(:events).through(:event_people) }
  end

  # ── Virtual attribute ─────────────────────────────────────────────────────
  describe "#full_name" do
    it "returns first and last name when no middle name" do
      lars = build(:person, :lars_ulrich)
      expect(lars.full_name).to eq("Lars Ulrich")
    end

    it "returns first middle and last name when all present" do
      james = build(:person, :james_hetfield)
      expect(james.full_name).to eq("James Alan Hetfield")
    end

    it "returns first middle and last name for all band members" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
      expect(build(:person, :kirk_hammett).full_name).to eq("Kirk Lee Hammett")
      expect(build(:person, :robert_trujillo).full_name).to eq("Robert Agustin Trujillo")
    end

    it "returns only first name when middle and last are blank" do
      james = build(:person, first_name: "James", middle_name: nil, last_name: nil)
      expect(james.full_name).to eq("James")
    end

    it "strips extra whitespace when middle name is blank" do
      james = build(:person, first_name: "James", middle_name: "", last_name: "Hetfield")
      expect(james.full_name).to eq("James Hetfield")
    end
  end

  describe "#slug" do
    it "generates a slug from full_name" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      expect(person.slug).to eq("james-hetfield")
    end

    it "regenerates the slug when the name changes" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      person.update!(last_name: "Newsted")
      expect(person.slug).to eq("james-newsted")
    end

    it "keeps the old slug resolvable after a name change" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      person.update!(last_name: "Newsted")
      expect(Person.friendly.find("james-hetfield")).to eq(person)
    end
  end
end
