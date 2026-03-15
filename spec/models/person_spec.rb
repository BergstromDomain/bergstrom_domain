require "rails_helper"

RSpec.describe Person, type: :model do
  subject { build(:person) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:firstname) }

    it "allows an empty lastname" do
      person = build(:person, lastname: nil)
      expect(person).to be_valid
    end

    it { is_expected.to validate_uniqueness_of(:firstname).scoped_to(:lastname) }
  end

  describe "#fullname" do
    it "returns the full name when firstname and lastname are present" do
      person = build(:person, firstname: "James", lastname: "Hetfield")
      expect(person.fullname).to eq("James Hetfield")
    end

    it "returns only firstname when lastname is blank" do
      person = build(:person, firstname: "Madonna", lastname: nil)
      expect(person.fullname).to eq("Madonna")
    end

    it "includes middlename when present" do
      person = build(:person, firstname: "James", middlename: "Alan", lastname: "Hetfield")
      expect(person.fullname).to eq("James Alan Hetfield")
    end
  end

  describe "slug generation" do
    it "generates a slug based on fullname when created" do
      person = create(:person, firstname: "Lars", lastname: "Ulrich")
      expect(person.slug).to eq("lars-ulrich")
    end

    it "generates a slug correctly when lastname is missing" do
      person = create(:person, firstname: "Madonna", lastname: nil)
      expect(person.slug).to eq("madonna")
    end

    it "does not overwrite an existing slug" do
      person = create(:person, firstname: "Kirk", lastname: "Hammett", slug: "custom-slug")
      expect(person.slug).to eq("custom-slug")
    end
  end

  describe "scopes" do
    it "sorts people alphabetically using lastname or firstname" do
      james = create(:person, firstname: "James", lastname: "Hetfield")
      madonna = create(:person, firstname: "Madonna", lastname: nil)
      lars = create(:person, firstname: "Lars", lastname: "Ulrich")

      expect(Person.alphabetical).to eq([james, madonna, lars])
    end

    it "finds people by firstname search" do
      james = create(:person, firstname: "James", lastname: "Hetfield")
      lars = create(:person, firstname: "Lars", lastname: "Ulrich")

      expect(Person.search_by_name("James")).to include(james)
      expect(Person.search_by_name("James")).not_to include(lars)
    end

    it "finds people by lastname search" do
      james = create(:person, firstname: "James", lastname: "Hetfield")
      lars = create(:person, firstname: "Lars", lastname: "Ulrich")

      expect(Person.search_by_name("Ulrich")).to include(lars)
      expect(Person.search_by_name("Ulrich")).not_to include(james)
    end
  end

  describe "image helpers" do
    it "returns the correct thumbnail URL" do
      person = build(:person, thumbnail_image: "james_thumb.jpg")

      expect(person.thumbnail_url).to eq(
        "/images/people/thumbnails/james_thumb.jpg"
      )
    end

    it "returns nil if thumbnail_image is blank" do
      person = build(:person, thumbnail_image: nil)

      expect(person.thumbnail_url).to be_nil
    end

    it "returns the correct full image URL" do
      person = build(:person, full_image: "james.jpg")

      expect(person.full_image_url).to eq(
        "/images/people/full/james.jpg"
      )
    end

    it "returns nil if full_image is blank" do
      person = build(:person, full_image: nil)

      expect(person.full_image_url).to be_nil
    end
  end
end