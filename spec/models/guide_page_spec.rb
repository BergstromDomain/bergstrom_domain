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
    it { is_expected.to have_db_column(:supports_guest).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:supports_user).of_type(:boolean).with_options(null: false, default: false) }
    it { is_expected.to have_db_column(:supports_content_creator).of_type(:boolean).with_options(null: false, default: false) }
  end

  # ── Enums ─────────────────────────────────────────────────────────────────
  describe "Enums" do
    it {
      is_expected.to define_enum_for(:app_section)
        .with_values(
          core: "core", event_tracker: "event_tracker", blog_posts: "blog_posts", admin: "admin"
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

      it "is valid for multiple guide pages to share the same app_section" do
        create(:guide_page, title: "Classification", app_section: "core")
        gp = build(:guide_page, title: "Sign Up", app_section: "core")
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

  # ── #app_section_label ───────────────────────────────────────────────────
  describe "#app_section_label" do
    it "returns the brand-facing label for the app_section" do
      expect(build(:guide_page, app_section: "event_tracker").app_section_label).to eq("Occasions")
      expect(build(:guide_page, app_section: "blog_posts").app_section_label).to eq("Chronicle")
      expect(build(:guide_page, app_section: "core").app_section_label).to eq("Core")
      expect(build(:guide_page, app_section: "admin").app_section_label).to eq("Admin")
    end
  end

  # ── .search ───────────────────────────────────────────────────────────────
  describe ".search" do
    # 1) Happy Path ───────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "matches guide pages by title" do
        matching = create(:guide_page, title: "Getting Started", body: "Unrelated content.")
        create(:guide_page, title: "Sign Up", body: "Unrelated content.")
        expect(GuidePage.search("getting")).to contain_exactly(matching)
      end

      it "matches guide pages by body content" do
        matching = create(:guide_page, title: "Sign Up", body: "How to create an account.")
        create(:guide_page, title: "Getting Started", body: "Welcome to the app.")
        expect(GuidePage.search("account")).to contain_exactly(matching)
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "returns no results when nothing matches" do
        create(:guide_page, title: "Getting Started", body: "Welcome.")
        expect(GuidePage.search("nonexistent term")).to be_empty
      end
    end

    # 3) Alternative Paths ───────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "returns all guide pages when the query is blank" do
        create_list(:guide_page, 2)
        expect(GuidePage.search("").count).to eq(2)
        expect(GuidePage.search(nil).count).to eq(2)
      end
    end

    # 4) Edge Cases ─────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "is case-insensitive" do
        matching = create(:guide_page, title: "Getting Started", body: "Welcome.")
        expect(GuidePage.search("GETTING")).to contain_exactly(matching)
      end

      it "escapes SQL LIKE wildcard characters in the query" do
        # Without escaping, "%" in the query would act as a SQL wildcard and
        # incorrectly match "50 apples" (since %50%% collapses to %50%).
        # With escaping it's treated as a literal character the body doesn't
        # contain, so no match.
        create(:guide_page, title: "Sign Up", body: "50 apples were purchased.")
        expect(GuidePage.search("50%")).to be_empty
      end
    end
  end

  # ── Support flags ─────────────────────────────────────────────────────────
  describe "support flags" do
    it "default to false for a new guide page" do
      gp = create(:guide_page)
      expect(gp.supports_guest).to eq(false)
      expect(gp.supports_user).to eq(false)
      expect(gp.supports_content_creator).to eq(false)
    end

    it "can be set independently" do
      gp = create(:guide_page, supports_guest: true, supports_user: false, supports_content_creator: true)
      expect(gp.supports_guest?).to eq(true)
      expect(gp.supports_user?).to eq(false)
      expect(gp.supports_content_creator?).to eq(true)
    end
  end
end
