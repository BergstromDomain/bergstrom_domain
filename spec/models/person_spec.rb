# spec/models/person_spec.rb
require "rails_helper"

RSpec.describe Person, type: :model do
  subject { build(:person) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "Database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:middle_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "contacts") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:event_people).dependent(:destroy) }
    it { is_expected.to have_many(:events).through(:event_people) }
    it { is_expected.to have_many(:person_social_media_accounts).dependent(:destroy) }
    it { is_expected.to have_many(:social_media_platforms).through(:person_social_media_accounts) }
    it { is_expected.to have_one_attached(:image) }
    it { is_expected.to accept_nested_attributes_for(:person_social_media_accounts).allow_destroy(true) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "Happy path" do
      context "Name" do
        it "Is valid when full name is unique" do
          create(:person, :james_hetfield)
          lars = build(:person, :lars_ulrich)
          expect(lars).to be_valid
        end
      end

      context "Classification" do
        it "Is valid with classification set to contacts" do
          expect(build(:person, classification: "contacts")).to be_valid
        end

        it "Is valid with classification set to unrestricted" do
          expect(build(:person, classification: "unrestricted")).to be_valid
        end

        it "Is valid with classification set to restricted" do
          expect(build(:person, classification: "restricted")).to be_valid
        end

        it "Defaults to contacts" do
          expect(build(:person).classification).to eq("contacts")
        end
      end

      context "User" do
        it "Is valid when a user is present" do
          expect(build(:person, user: create(:user))).to be_valid
        end
      end

      context "Image type" do
        it "Is valid with a JPEG image" do
          person = build(:person)
          person.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
            filename:     "test_image.jpg",
            content_type: "image/jpeg"
          )
          expect(person).to be_valid
        end

        it "Is valid with a PNG image" do
          person = build(:person)
          person.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
            filename:     "test_image.png",
            content_type: "image/png"
          )
          expect(person).to be_valid
        end

        it "Is valid with a WebP image" do
          person = build(:person)
          person.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
            filename:     "test_image.webp",
            content_type: "image/webp"
          )
          expect(person).to be_valid
        end
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "Negative path" do
      it { is_expected.to validate_presence_of(:first_name) }

      context "Name" do
        it "Is not valid when first name is missing" do
          person = build(:person, first_name: "")
          expect(person).not_to be_valid
          expect(person.errors[:first_name]).to include("can't be blank")
        end

        it "Is not valid when full name already exists" do
          create(:person, :kirk_hammett)
          duplicate = build(:person, :kirk_hammett)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "Treats nil middle name the same as blank" do
          create(:person, :lars_ulrich)
          duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "Ulrich")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "Treats nil last name the same as blank" do
          create(:person, first_name: "Lars", middle_name: nil, last_name: nil)
          duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end
      end

      context "Classification" do
        it "Is not valid without a classification" do
          subject.classification = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:classification]).to be_present
        end

        it "Is not valid when classification is set to an unrecognised value" do
          person = build(:person)
          person.classification = "top_secret"
          expect(person).not_to be_valid
          expect(person.errors[:classification]).to be_present
        end
      end

      context "User" do
        it "Is not valid without a user" do
          subject.user = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to be_present
        end
      end

      context "Image type" do
        it "Is not valid with a text file as image" do
          person = build(:person)
          person.image.attach(
            io:           StringIO.new("not an image"),
            filename:     "bad.txt",
            content_type: "text/plain"
          )
          expect(person).not_to be_valid
          expect(person.errors[:image]).to be_present
        end

        it "Is not valid with a GIF image" do
          person = build(:person)
          person.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
            filename:     "test_image.gif",
            content_type: "image/gif"
          )
          expect(person).not_to be_valid
          expect(person.errors[:image]).to be_present
        end

        it "Is not valid with an image exceeding 5MB" do
          person = build(:person)
          person.image.attach(
            io:           StringIO.new("0" * (5.megabytes + 1)),
            filename:     "huge.jpg",
            content_type: "image/jpeg"
          )
          expect(person).not_to be_valid
          expect(person.errors[:image]).to be_present
        end
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "Alternative path" do
      context "Name" do
        it "Is valid with only a first name" do
          person = build(:person, first_name: "Cliff", middle_name: nil, last_name: nil)
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff")
        end

        it "Is valid with first name and middle name only" do
          person = build(:person, first_name: "Cliff", middle_name: "Lee", last_name: nil)
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff Lee")
        end

        it "Is valid with first name and last name only" do
          person = build(:person, first_name: "Cliff", middle_name: nil, last_name: "Burton")
          expect(person).to be_valid
          expect(person.full_name).to eq("Cliff Burton")
        end

        it "Is valid with first, middle, and last name" do
          person = build(:person, :james_hetfield)
          expect(person).to be_valid
          expect(person.full_name).to eq("James Alan Hetfield")
        end
      end

      context "Description" do
        it "Is valid when updating description without changing the name" do
          person = create(:person, :james_hetfield)
          person.description = "Updated description"
          expect(person).to be_valid
        end
      end

      context "Classification" do
        it "retains the classification when other attributes are updated" do
          person = create(:person, :james_hetfield, classification: "restricted")
          person.update!(first_name: "Jim")
          expect(person.reload.classification).to eq("restricted")
        end
      end

      context "Slug" do
        it "Slug is regenerated when full name changes" do
          person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
          person.update!(last_name: "Newsted")
          expect(person.slug).to eq("james-newsted")
        end
      end

      describe "#bucket_letter" do
        it "Buckets by the first letter of last_name when present" do
          person = build(:person, first_name: "Lars", last_name: "Ulrich")
          expect(person.bucket_letter).to eq("U")
        end

        it "Buckets by the first letter of first_name when last_name is blank" do
          person = build(:person, :first_name_only, first_name: "Cliff")
          expect(person.bucket_letter).to eq("C")
        end

        it "Is case-insensitive on the input, upcased on the output" do
          person = build(:person, first_name: "lars", last_name: "ulrich")
          expect(person.bucket_letter).to eq("U")
        end
      end

      describe "Swedish case-folding at the database level" do
        it "Confirms Postgres UPPER() itself round-trips å/ä/ö, not just Ruby's upcase" do
          result = ActiveRecord::Base.connection.select_value("SELECT UPPER('åäö')")
          expect(result).to eq("ÅÄÖ")
        end
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "Edge cases" do
      context "Name" do
        it "Is not valid when full name collides despite different middle and last name positions" do
          create(:person, first_name: "Alfa", middle_name: nil,       last_name: "Charlie")
          duplicate = build(:person,  first_name: "Alfa", middle_name: "Charlie", last_name: nil)
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "Is not valid when full name already exists in a different case" do
          create(:person, first_name: "James", middle_name: "Alan", last_name: "Hetfield")
          duplicate = build(:person, first_name: "james", middle_name: "alan", last_name: "hetfield")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end

        it "Is not valid when first name differs only in case" do
          create(:person, first_name: "Lars", middle_name: nil, last_name: "Ulrich")
          duplicate = build(:person, first_name: "lars", middle_name: nil, last_name: "Ulrich")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:base]).to include("Full name has already been taken")
        end
      end

      context "Slug" do
        it "Old slug is resolvable after a name change" do
          person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
          person.update!(last_name: "Newsted")
          expect(Person.friendly.find("james-hetfield")).to eq(person)
        end
      end
    end
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  describe "#full_name" do
    it "Returns first and last name when no middle name" do
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
    end

    it "Returns first, middle, and last name when all present" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
    end

    it "Returns first, middle, and last name for all band members" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
      expect(build(:person, :kirk_hammett).full_name).to eq("Kirk Lee Hammett")
      expect(build(:person, :robert_trujillo).full_name).to eq("Robert Agustin Trujillo")
    end

    it "Returns only first name when middle and last are blank" do
      expect(build(:person, first_name: "James", middle_name: nil, last_name: nil).full_name).to eq("James")
    end

    it "Strips extra whitespace when middle name is blank" do
      expect(build(:person, first_name: "James", middle_name: "", last_name: "Hetfield").full_name).to eq("James Hetfield")
    end
  end

  describe "#to_toast_label" do
    it "Delegates to full_name" do
      person = build(:person, :james_hetfield)
      expect(person.to_toast_label).to eq(person.full_name)
    end
  end

  describe "#slug" do
    it "Generates a slug from full_name" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      expect(person.slug).to eq("james-hetfield")
    end

    it "Regenerates the slug when the name changes" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      person.update!(last_name: "Newsted")
      expect(person.slug).to eq("james-newsted")
    end

    it "Keeps the old slug resolvable after a name change" do
      person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
      person.update!(last_name: "Newsted")
      expect(Person.friendly.find("james-hetfield")).to eq(person)
    end
  end

  describe "#person_social_media_accounts_attributes=" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "Happy path" do
      it "Creates a new account when a platform and username are given" do
        person = create(:person, :james_hetfield)
        platform = create(:social_media_platform)
        person.update!(person_social_media_accounts_attributes: [
          { social_media_platform_id: platform.id, username: "jhetfield" }
        ])
        expect(person.social_media_platforms).to include(platform)
      end

      it "Destroys an existing account when _destroy is set" do
        person = create(:person, :james_hetfield)
        account = create(:person_social_media_account, person: person)
        person.reload
        person.update!(person_social_media_accounts_attributes: [
          { id: account.id, _destroy: "1" }
        ])
        expect(person.person_social_media_accounts.reload).to be_empty
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "Negative path" do
      it "Is invalid when two accounts for the same person share a platform" do
        person = create(:person, :james_hetfield)
        platform = create(:social_media_platform)
        person.person_social_media_accounts_attributes = [
          { social_media_platform_id: platform.id, username: "one" },
          { social_media_platform_id: platform.id, username: "two" }
        ]
        expect(person).not_to be_valid
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "Alternative path" do
      it "Updates the username on an existing account without creating a new one" do
        person = create(:person, :james_hetfield)
        account = create(:person_social_media_account, person: person, username: "old_handle")
        person.reload
        expect {
          person.update!(person_social_media_accounts_attributes: [
            { id: account.id, username: "new_handle" }
          ])
        }.not_to change(PersonSocialMediaAccount, :count)
        expect(account.reload.username).to eq("new_handle")
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "Edge cases" do
      it "Ignores a blank row instead of raising a validation error" do
        person = create(:person, :james_hetfield)
        person.person_social_media_accounts_attributes = [
          { social_media_platform_id: "", username: "" }
        ]
        expect(person).to be_valid
        expect(person.person_social_media_accounts).to be_empty
      end
    end
  end
end
