# spec/models/event_spec.rb
require "rails_helper"

RSpec.describe Event, type: :model do
  subject { build(:event) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:day).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:month).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:year).of_type(:integer) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
    it { is_expected.to have_db_column(:event_type_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "contacts") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to belong_to(:event_type) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:event_people).dependent(:destroy) }
    it { is_expected.to have_many(:people).through(:event_people) }
    it { is_expected.to have_one_attached(:image) }
    it { is_expected.to have_one_attached(:thumbnail_image) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      context "title" do
        it "is valid when title is unique" do
          create(:event, title: "Kill 'Em All")
          event = build(:event, title: "Ride the Lightning")
          expect(event).to be_valid
        end
      end

      context "day" do
        it "is valid when day is present" do
          event = build(:event, day: 15)
          expect(event).to be_valid
        end
      end

      context "month" do
        it "is valid when month is present" do
          event = build(:event, month: 6)
          expect(event).to be_valid
        end
      end

      context "classification" do
        it "is valid with classification set to contacts" do
          expect(build(:event, classification: "contacts")).to be_valid
        end

        it "is valid with classification set to unrestricted" do
          expect(build(:event, classification: "unrestricted")).to be_valid
        end

        it "is valid with classification set to restricted" do
          expect(build(:event, classification: "restricted")).to be_valid
        end

        it "defaults to contacts" do
          expect(build(:event).classification).to eq("contacts")
        end
      end

      context "user" do
        it "is valid when a user is present" do
          expect(build(:event, user: create(:user))).to be_valid
        end
      end

      context "thumbnail image type" do
        it "is valid with a JPEG thumbnail image" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
            filename:     "test_image.jpg",
            content_type: "image/jpeg"
          )
          expect(event).to be_valid
        end

        it "is valid with a PNG thumbnail image" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
            filename:     "test_image.png",
            content_type: "image/png"
          )
          expect(event).to be_valid
        end

        it "is valid with a WebP thumbnail image" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
            filename:     "test_image.webp",
            content_type: "image/webp"
          )
          expect(event).to be_valid
        end
      end

      context "image type" do
        it "is valid with a JPEG image" do
          event = build(:event)
          event.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
            filename:     "test_image.jpg",
            content_type: "image/jpeg"
          )
          expect(event).to be_valid
        end

        it "is valid with a PNG image" do
          event = build(:event)
          event.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
            filename:     "test_image.png",
            content_type: "image/png"
          )
          expect(event).to be_valid
        end

        it "is valid with a WebP image" do
          event = build(:event)
          event.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.webp")),
            filename:     "test_image.webp",
            content_type: "image/webp"
          )
          expect(event).to be_valid
        end
      end

      context "slug" do
        it "generates a slug from the title" do
          event = create(:event, title: "Kill 'Em All")
          expect(event.slug).to eq("kill-em-all")
        end
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_uniqueness_of(:title).case_insensitive }
      it { is_expected.to validate_presence_of(:day) }
      it { is_expected.to validate_numericality_of(:day)
            .only_integer
            .is_greater_than_or_equal_to(1)
            .is_less_than_or_equal_to(31) }
      it { is_expected.to validate_presence_of(:month) }
      it { is_expected.to validate_numericality_of(:month)
            .only_integer
            .is_greater_than_or_equal_to(1)
            .is_less_than_or_equal_to(12) }
      it { is_expected.to validate_numericality_of(:year)
            .only_integer
            .is_greater_than_or_equal_to(1000)
            .allow_nil }

      context "title" do
        it "is not valid when title is missing" do
          event = build(:event, title: "")
          expect(event).not_to be_valid
          expect(event.errors[:title]).to include("can't be blank")
        end

        it "is not valid when title already exists" do
          create(:event, title: "Kill 'Em All")
          duplicate = build(:event, title: "Kill 'Em All")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:title]).to include("has already been taken")
        end

        it "is not valid when trimmed title already exists" do
          create(:event, title: "Kill 'Em All")
          duplicate = build(:event, title: "  Kill 'Em All  ")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:title]).to include("has already been taken")
        end

        it "is not valid when title already exists in a different case" do
          create(:event, title: "Kill 'Em All")
          duplicate = build(:event, title: "kill 'em all")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:title]).to include("has already been taken")
        end

        it "is not valid when title with collapsed internal spaces already exists" do
          create(:event, title: "Kill 'Em All")
          duplicate = build(:event, title: "Kill  'Em   All")
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:title]).to include("has already been taken")
        end
      end

      context "classification" do
        it "is not valid without a classification" do
          subject.classification = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:classification]).to be_present
        end

        it "is not valid when classification is set to an unrecognised value" do
          event = build(:event)
          event.classification = "top_secret"
          expect(event).not_to be_valid
          expect(event.errors[:classification]).to be_present
        end
      end

      context "user" do
        it "is not valid without a user" do
          subject.user = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to be_present
        end
      end

      context "day" do
        it "is not valid when day is not an integer" do
          event = build(:event, day: 1.5)
          expect(event).not_to be_valid
          expect(event.errors[:day]).to be_present
        end

        it "is not valid when day is less than 1" do
          event = build(:event, day: 0)
          expect(event).not_to be_valid
          expect(event.errors[:day]).to be_present
        end

        it "is not valid when day is greater than 31" do
          event = build(:event, day: 32)
          expect(event).not_to be_valid
          expect(event.errors[:day]).to be_present
        end
      end

      context "month" do
        it "is not valid when month is not an integer" do
          event = build(:event, month: 1.5)
          expect(event).not_to be_valid
          expect(event.errors[:month]).to be_present
        end

        it "is not valid when month is less than 1" do
          event = build(:event, month: 0)
          expect(event).not_to be_valid
          expect(event.errors[:month]).to be_present
        end

        it "is not valid when month is greater than 12" do
          event = build(:event, month: 13)
          expect(event).not_to be_valid
          expect(event.errors[:month]).to be_present
        end
      end

      context "year" do
        it "is not valid when year is not an integer" do
          event = build(:event, year: 1983.5)
          expect(event).not_to be_valid
          expect(event.errors[:year]).to be_present
        end

        it "is not valid when year is less than 1000" do
          event = build(:event, year: 999)
          expect(event).not_to be_valid
          expect(event.errors[:year]).to be_present
        end
      end

      context "thumbnail image type" do
        it "is not valid with a text file as thumbnail image" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           StringIO.new("not an image"),
            filename:     "bad.txt",
            content_type: "text/plain"
          )
          expect(event).not_to be_valid
          expect(event.errors[:thumbnail_image]).to be_present
        end

        it "is not valid with a GIF thumbnail image" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
            filename:     "test_image.gif",
            content_type: "image/gif"
          )
          expect(event).not_to be_valid
          expect(event.errors[:thumbnail_image]).to be_present
        end

        it "is not valid with a thumbnail image exceeding 5MB" do
          event = build(:event)
          event.thumbnail_image.attach(
            io:           StringIO.new("0" * (5.megabytes + 1)),
            filename:     "huge.jpg",
            content_type: "image/jpeg"
          )
          expect(event).not_to be_valid
          expect(event.errors[:thumbnail_image]).to be_present
        end
      end

      context "image type" do
        it "is not valid with a text file as image" do
          event = build(:event)
          event.image.attach(
            io:           StringIO.new("not an image"),
            filename:     "bad.txt",
            content_type: "text/plain"
          )
          expect(event).not_to be_valid
          expect(event.errors[:image]).to be_present
        end

        it "is not valid with a GIF image" do
          event = build(:event)
          event.image.attach(
            io:           File.open(Rails.root.join("spec/fixtures/files/test_image.gif")),
            filename:     "test_image.gif",
            content_type: "image/gif"
          )
          expect(event).not_to be_valid
          expect(event.errors[:image]).to be_present
        end

        it "is not valid with an image exceeding 5MB" do
          event = build(:event)
          event.image.attach(
            io:           StringIO.new("0" * (5.megabytes + 1)),
            filename:     "huge.jpg",
            content_type: "image/jpeg"
          )
          expect(event).not_to be_valid
          expect(event.errors[:image]).to be_present
        end
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      context "description" do
        it "is valid when updating description without changing the title" do
          event = create(:event, title: "Kill 'Em All")
          event.description = "Updated description"
          expect(event).to be_valid
        end

        it "is valid without a description" do
          event = build(:event, description: nil)
          expect(event).to be_valid
        end
      end

      context "classification" do
        it "retains the classification when other attributes are updated" do
          event = create(:event, :restricted)
          event.update!(title: "Updated Title")
          expect(event.reload.classification).to eq("restricted")
        end
      end

      context "year" do
        it "is valid without a year" do
          event = build(:event, year: nil)
          expect(event).to be_valid
        end
      end

      context "slug" do
        it "slug is regenerated when title changes" do
          event = create(:event, title: "Kill 'Em All")
          event.update!(title: "Ride the Lightning")
          expect(event.slug).to eq("ride-the-lightning")
        end
      end
    end

    # 4) Edge cases ───────────────────────────────────────────────────────────
    describe "edge cases" do
      context "date" do
        it "is not valid when day and month do not form a valid date" do
          event = build(:event, day: 31, month: 2, year: 1983)
          expect(event).not_to be_valid
          expect(event.errors[:base]).to include("Date is not valid")
        end

        it "is not valid when February 29 is given without a year" do
          event = build(:event, day: 29, month: 2, year: nil)
          expect(event).not_to be_valid
          expect(event.errors[:base]).to include("Date is not valid")
        end

        it "is not valid when February 29 is given for a non-leap year" do
          event = build(:event, day: 29, month: 2, year: 1983)
          expect(event).not_to be_valid
          expect(event.errors[:base]).to include("Date is not valid")
        end

        it "is valid when February 29 is given for a leap year" do
          event = build(:event, day: 29, month: 2, year: 2000)
          expect(event).to be_valid
        end
      end

      context "slug" do
        it "old slug is resolvable after a title change" do
          event = create(:event, title: "Kill 'Em All")
          event.update!(title: "Ride the Lightning")
          expect(Event.friendly.find("kill-em-all")).to eq(event)
        end
      end
    end
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  describe "#display_date" do
    it "returns day and month when year is nil" do
      event = build(:event, day: 25, month: 5, year: nil)
      expect(event.display_date).to eq("25 May")
    end

    it "returns full date when year is present" do
      event = build(:event, day: 25, month: 5, year: 1983)
      expect(event.display_date).to eq("25 May 1983")
    end

    it "returns month name not month number" do
      event = build(:event, day: 1, month: 1, year: 2000)
      expect(event.display_date).to eq("1 Jan 2000")
    end
  end

  describe "#slug" do
    it "generates a slug from the title" do
      event = create(:event, title: "Kill 'Em All")
      expect(event.slug).to eq("kill-em-all")
    end

    it "regenerates the slug when the title changes" do
      event = create(:event, title: "Kill 'Em All")
      event.update!(title: "Ride the Lightning")
      expect(event.slug).to eq("ride-the-lightning")
    end

    it "keeps the old slug resolvable after a title change" do
      event = create(:event, title: "Kill 'Em All")
      event.update!(title: "Ride the Lightning")
      expect(Event.friendly.find("kill-em-all")).to eq(event)
    end
  end
end
