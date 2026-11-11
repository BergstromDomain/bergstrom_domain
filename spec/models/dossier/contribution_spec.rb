# spec/models/dossier/contribution_spec.rb
require "rails_helper"

RSpec.describe Dossier::Contribution, type: :model do
  let(:user) { create(:user, :content_creator) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:kind).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:location).of_type(:string) }
    it { is_expected.to have_db_column(:url).of_type(:string) }
    it { is_expected.to have_db_column(:presented_as).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event).class_name("Dossier::Organisation").optional }
    it { is_expected.to belong_to(:engagement).optional }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is a talk at an event on a day, with Skills, shown by its title" do
      meetup = create(:dossier_organisation, name: "All Things Testing Brisbane")
      talk = create(:dossier_contribution, user: user, title: " Statistical Methods in Software Testing ", event: meetup,
                                           start_month: "2023-04", start_day: "19", location: "The Annex, Brisbane City",
                                           presented_as: "Technical Test Specialist", skills_text: "Statistics, Knowledge Sharing")

      expect(talk).to have_attributes(title: "Statistical Methods in Software Testing", kind_label: "Talk",
                                      date: "19 Apr 2023", to_toast_label: "Statistical Methods in Software Testing")
      expect(talk.skills.map(&:name)).to eq([ "Statistics", "Knowledge Sharing" ])
      expect(user.dossier_contributions).to eq([ talk ])
    end

    it "Soft deletes and restores" do
      talk = create(:dossier_contribution, user: user)

      talk.soft_delete!
      expect(described_class.kept).to be_empty
      expect(talk.purge_at).to be_within(1.second).of(talk.deleted_at + 30.days)
      talk.restore!
      expect(described_class.kept).to eq([ talk ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a title, a known kind and a date" do
      contribution = described_class.new(user: user, kind: "lecture", title: " ")

      expect(contribution).not_to be_valid
      expect(contribution.errors[:title]).to include("can't be blank")
      expect(contribution.errors[:kind]).to include("is not included in the list")
      expect(contribution.errors[:start_month]).to include("can't be blank")
    end

    it "Needs a link that's a web address" do
      contribution = build(:dossier_contribution, url: "youtube.com/watch?v=1")

      expect(contribution).not_to be_valid
      expect(contribution.errors[:url]).to include("must start with http:// or https://")
    end

    it "Takes only PDF and image files up to 10 MB" do
      contribution = build(:dossier_contribution)
      contribution.files.attach(io: StringIO.new("text"), filename: "notes.txt", content_type: "text/plain")

      expect(contribution).not_to be_valid
      expect(contribution.errors[:files]).to include("must be a PDF, JPEG, PNG, WebP or AVIF")
    end

    it "Won't sit under someone else's Engagement" do
      contribution = build(:dossier_contribution, user: user, engagement: create(:dossier_engagement))

      expect(contribution).not_to be_valid
      expect(contribution.errors[:engagement]).to include("must be one of your Engagements")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Takes a month or a year on its own" do
      expect(build(:dossier_contribution, start_month: "2024-11", start_day: "").date).to eq("Nov 2024")
      expect(build(:dossier_contribution, start_month: "2024", start_day: "").date).to eq("2024")
    end

    it "Lists newest first, by kind in the kinds' order" do
      older = create(:dossier_contribution, user: user, start_month: "2023-04")
      newer = create(:dossier_contribution, user: user, start_month: "2024-11")
      article = create(:dossier_contribution, user: user, kind: "article", start_month: "2025-01")

      expect(described_class.newest_first).to eq([ article, newer, older ])
      expect(described_class::KINDS.keys.first(2)).to eq(%w[talk workshop])
      expect(article.kind_label).to eq("Article")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Stays when its Engagement goes, and its event can't be deleted while it's used" do
      engagement = create(:dossier_engagement, user: user)
      meetup = create(:dossier_organisation, name: "All Things Testing Brisbane")
      talk = create(:dossier_contribution, user: user, engagement: engagement, event: meetup)

      engagement.destroy!
      expect(talk.reload.engagement).to be_nil
      expect(meetup.destroy).to be(false)
    end

    it "Is the same day for start and end, so it's never current" do
      talk = create(:dossier_contribution, start_month: "2024-11", start_day: "19")

      expect(talk).to have_attributes(end_on: Date.new(2024, 11, 19), end_precision: "day", current?: false)
    end

    it "Blanks empty optional fields" do
      talk = create(:dossier_contribution, location: " ", url: " ", presented_as: "", description: " ")

      expect(talk).to have_attributes(location: nil, url: nil, presented_as: nil, description: nil)
    end
  end
end
