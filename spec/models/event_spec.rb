require "rails_helper"

RSpec.describe Event, type: :model do
  subject(:event) { build(:event) }

  # ── Associations (coming later) ───────────────────────────────────────────
  # belongs_to :person
  # belongs_to :event_type

  # ── Database columns ─────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:day).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:month).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:year).of_type(:integer) }
    it { is_expected.to have_db_column(:image).of_type(:string) }
    it { is_expected.to have_db_column(:thumbnail_image).of_type(:string) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
    it { is_expected.to have_db_column(:event_type_id).of_type(:integer).with_options(null: false) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title).case_insensitive }

    it { is_expected.to validate_presence_of(:day) }
    it { is_expected.to validate_presence_of(:month) }

    it { is_expected.to validate_numericality_of(:day).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(31) }
    it { is_expected.to validate_numericality_of(:month).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12) }
    it { is_expected.to validate_numericality_of(:year).is_greater_than(0).allow_nil }

    context "title uniqueness" do
      it "is valid when title is unique" do
        create(:event, title: "Kill 'Em All")
        event = build(:event, title: "Ride the Lightning")
        expect(event).to be_valid
      end

      it "is invalid when title already exists" do
        create(:event, title: "Kill 'Em All")
        duplicate = build(:event, title: "Kill 'Em All")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:title]).to include("has already been taken")
      end

      it "is case-insensitive" do
        create(:event, title: "Kill 'Em All")
        duplicate = build(:event, title: "kill 'em all")
        expect(duplicate).not_to be_valid
      end
    end

    context "year is optional" do
      it "is valid without a year" do
        event = build(:event, year: nil)
        expect(event).to be_valid
      end
    end

    context "description is optional" do
      it "is valid without a description" do
        event = build(:event, description: nil)
        expect(event).to be_valid
      end
    end

    context "image fields are optional" do
      it "is valid without an image" do
        event = build(:event, image: nil, thumbnail_image: nil)
        expect(event).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:event_type) }
  end

  # ── #display_date ─────────────────────────────────────────────────────────
  describe "#display_date" do
    it "returns month/day when year is nil" do
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

  # ── #slug ─────────────────────────────────────────────────────────────────
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
