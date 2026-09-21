# spec/models/guide_page_spec.rb
require "rails_helper"

RSpec.describe GuidePage, type: :model do
  subject { build(:guide_page) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:app_section).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:body).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Enums ─────────────────────────────────────────────────────────────────
  describe "Enums" do
    it {
      is_expected.to define_enum_for(:app_section)
        .with_values(
          core: "core", event_tracker: "event_tracker", blog_posts: "blog_posts",
          recipes: "recipes", photo_albums: "photo_albums", admin: "admin"
        ).backed_by_column_of_type(:string)
    }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "Validations" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "is valid with all required fields" do
        gp = build(:guide_page, title: "Getting Started", app_section: "core", body: "Welcome.")
        expect(gp).to be_valid
      end
    end

    # 2) Negative Path ────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "is invalid when title is blank" do
        gp = build(:guide_page, title: "")
        expect(gp).not_to be_valid
        expect(gp.errors[:title]).to include("can't be blank")
      end

      it "is invalid when title is a duplicate (same case)" do
        create(:guide_page, title: "Getting Started", app_section: "core")
        gp = build(:guide_page, title: "Getting Started", app_section: "event_tracker")
        expect(gp).not_to be_valid
        expect(gp.errors[:title]).to include("has already been taken")
      end

      it "is invalid when title is a duplicate (different case)" do
        create(:guide_page, title: "Getting Started", app_section: "core")
        gp = build(:guide_page, title: "getting started", app_section: "event_tracker")
        expect(gp).not_to be_valid
        expect(gp.errors[:title]).to include("has already been taken")
      end

      it "is invalid when app_section is blank" do
        gp = build(:guide_page, app_section: nil)
        expect(gp).not_to be_valid
        expect(gp.errors[:app_section]).to include("can't be blank")
      end

      it "is invalid when app_section is already taken by another record" do
        create(:guide_page, title: "Core Guide", app_section: "core")
        gp = build(:guide_page, title: "Another Core Guide", app_section: "core")
        expect(gp).not_to be_valid
        expect(gp.errors[:app_section]).to include("has already been taken")
      end

      it "is invalid when body is blank" do
        gp = build(:guide_page, body: "")
        expect(gp).not_to be_valid
        expect(gp.errors[:body]).to include("can't be blank")
      end
    end

    # 3) Alternative Paths ─────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "is valid when updating body without changing title or app_section" do
        gp = create(:guide_page, title: "Travel Guide", app_section: "core")
        gp.body = "Updated body."
        expect(gp).to be_valid
      end
    end

    # 4) Edge Cases ───────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is invalid when app_section is not a recognized value" do
        gp = build(:guide_page, app_section: "not_a_real_section")
        expect(gp).not_to be_valid
        expect(gp.errors[:app_section]).to include("is not included in the list")
      end
    end
  end

  # ── FriendlyId ────────────────────────────────────────────────────────────
  describe "FriendlyId" do
    it "generates a slug from title on create" do
      gp = create(:guide_page, title: "Getting Started", app_section: "core")
      expect(gp.slug).to eq("getting-started")
    end

    it "regenerates slug when title changes" do
      gp = create(:guide_page, title: "Travel Guide", app_section: "core")
      gp.update!(title: "Adventure Guide")
      gp.reload
      expect(gp.slug).to eq("adventure-guide")
    end

    it "resolves the old slug after a title change" do
      gp = create(:guide_page, title: "Sport Guide", app_section: "core")
      gp.update!(title: "Athletics Guide")
      expect(GuidePage.friendly.find("sport-guide")).to eq(gp)
    end
  end

  # ── MarkdownRenderable ────────────────────────────────────────────────────
  describe "#rendered_body" do
    it "renders body markdown to HTML" do
      gp = build(:guide_page, body: "**bold text**")
      expect(gp.rendered_body).to include("<strong>bold text</strong>")
    end
  end

  describe "#to_toast_label" do
    it "delegates to title" do
      gp = build(:guide_page)
      expect(gp.to_toast_label).to eq(gp.title)
    end
  end
end
