# spec/models/person_spec.rb
require "rails_helper"

RSpec.describe Person, type: :model do
  subject { build(:person) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:middle_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to have_many(:event_people).dependent(:destroy) }
    it { is_expected.to have_many(:events).through(:event_people) }
    it { is_expected.to have_one_attached(:thumbnail_image) }
    it { is_expected.to have_one_attached(:full_image) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      context "name" do
        it "is valid when full name is unique" do
          create(:person, :james_hetfield)
          lars = build(:person, :lars_ulrich)
          expect(lars).to be_valid
        end
      end

      context "thumbnail image type" do
        it "is valid with a JPEG thumbnail image" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
            filename:     "test_image.jpg",
            content_type: "image/jpeg"
          )
          expect(person).to be_valid
        end

        it "is valid with a PNG thumbnail image" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
            filename:     "test_image.png",
            content_type: "image/png"
          )
          expect(person).to be_valid
        end

        it "is valid with a WebP thumbnail image" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
            filename:     "test_image.webp",
            content_type: "image/webp"
          )
          expect(person).to be_valid
        end
      end

      context "full image type" do
        it "is valid with a JPEG full image" do
          person = build(:person)
          person.full_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
            filename:     "test_image.jpg",
            content_type: "image/jpeg"
          )
          expect(person).to be_valid
        end

        it "is valid with a PNG full image" do
          person = build(:person)
          person.full_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
            filename:     "test_image.png",
            content_type: "image/png"
          )
          expect(person).to be_valid
        end

        it "is valid with a WebP full image" do
          person = build(:person)
          person.full_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
            filename:     "test_image.webp",
            content_type: "image/webp"
          )
          expect(person).to be_valid
        end
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it { is_expected.to validate_presence_of(:first_name) }

      context "name" do
        it "is not valid when first name is missing" do
          person = build(:person, first_name: "")
          expect(person).not_to be_valid
          expect(person.errors[:first_name]).to include("can't be blank")
        end

        it "is not valid when full name already exists" do
          create(:person, :kirk_hammett)
          duplicate = build(:person, :kirk_hammett)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "treats nil middle name the same as blank" do
          create(:person, :lars_ulrich)
          duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "Ulrich")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "treats nil last name the same as blank" do
          create(:person, first_name: "Lars", middle_name: nil, last_name: nil)
          duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end
      end

      context "thumbnail image type" do
        it "is not valid with a text file as thumbnail image" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           StringIO.new("not an image"),
            filename:     "bad.txt",
            content_type: "text/plain"
          )
          expect(person).not_to be_valid
          expect(person.errors[:thumbnail_image]).to be_present
        end

        it "is not valid with a GIF thumbnail image" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
            filename:     "test_image.gif",
            content_type: "image/gif"
          )
          expect(person).not_to be_valid
          expect(person.errors[:thumbnail_image]).to be_present
        end

        it "is not valid with a thumbnail image exceeding 5MB" do
          person = build(:person)
          person.thumbnail_image.attach(
            io:           StringIO.new("0" * (5.megabytes + 1)),
            filename:     "huge.jpg",
            content_type: "image/jpeg"
          )
          expect(person).not_to be_valid
          expect(person.errors[:thumbnail_image]).to be_present
        end
      end

      context "full image type" do
        it "is not valid with a text file as full image" do
          person = build(:person)
          person.full_image.attach(
            io:           StringIO.new("not an image"),
            filename:     "bad.txt",
            content_type: "text/plain"
          )
          expect(person).not_to be_valid
          expect(person.errors[:full_image]).to be_present
        end

        it "is not valid with a GIF full image" do
          person = build(:person)
          person.full_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
            filename:     "test_image.gif",
            content_type: "image/gif"
          )
          expect(person).not_to be_valid
          expect(person.errors[:full_image]).to be_present
        end

        it "is not valid with a full image exceeding 5MB" do
          person = build(:person)
          person.full_image.attach(
            io:           StringIO.new("0" * (5.megabytes + 1)),
            filename:     "huge.jpg",
            content_type: "image/jpeg"
          )
          expect(person).not_to be_valid
          expect(person.errors[:full_image]).to be_present
        end
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      context "name" do
        it "is valid with only a first name" do
          person = build(:person, first_name: "Cliff", middle_name: nil, last_name: nil)
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff")
        end

        it "is valid with first name and middle name only" do
          person = build(:person, first_name: "Cliff", middle_name: "Lee", last_name: nil)
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff Lee")
        end

        it "is valid with first name and last name only" do
          person = build(:person, first_name: "Cliff", middle_name: nil, last_name: "Burton")
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff Burton")
        end

        it "is valid with first, middle, and last name" do
          person = build(:person, :james_hetfield)
          expect(person).to be_valid
          expect(person.full_name).to eq("James Alan Hetfield")
        end
      end

      context "description" do
        it "is valid when updating description without changing the name" do
          person = create(:person, :james_hetfield)
          person.description = "Updated description"
          expect(person).to be_valid
        end
      end

      context "slug" do
        it "slug is regenerated when full name changes" do
          person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
          person.update!(last_name: "Newsted")
          expect(person.slug).to eq("james-newsted")
        end
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      context "name" do
        it "is not valid when full name collides despite different middle and last name positions" do
          create(:person, first_name: "Alfa", middle_name: nil,       last_name: "Charlie")
          duplicate = build(:person,  first_name: "Alfa", middle_name: "Charlie", last_name: nil)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "is not valid when full name already exists in a different case" do
          create(:person, first_name: "James", middle_name: "Alan", last_name: "Hetfield")
          duplicate = build(:person, first_name: "james", middle_name: "alan", last_name: "hetfield")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "is not valid when first name differs only in case" do
          create(:person, first_name: "Lars", middle_name: nil, last_name: "Ulrich")
          duplicate = build(:person, first_name: "lars", middle_name: nil, last_name: "Ulrich")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end
      end

      context "slug" do
        it "old slug is resolvable after a name change" do
          person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
          person.update!(last_name: "Newsted")
          expect(Person.friendly.find("james-hetfield")).to eq(person)
        end
      end
    end
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  describe "#full_name" do
    it "returns first and last name when no middle name" do
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
    end

    it "returns first, middle, and last name when all present" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
    end

    it "returns first, middle, and last name for all band members" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
      expect(build(:person, :kirk_hammett).full_name).to eq("Kirk Lee Hammett")
      expect(build(:person, :robert_trujillo).full_name).to eq("Robert Agustin Trujillo")
    end

    it "returns only first name when middle and last are blank" do
      expect(build(:person, first_name: "James", middle_name: nil, last_name: nil).full_name).to eq("James")
    end

    it "strips extra whitespace when middle name is blank" do
      expect(build(:person, first_name: "James", middle_name: "", last_name: "Hetfield").full_name).to eq("James Hetfield")
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
