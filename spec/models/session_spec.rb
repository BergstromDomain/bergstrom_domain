# spec/models/session_spec.rb
require "rails_helper"

RSpec.describe Session, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:left_nav_visible).of_type(:boolean).with_options(null: false, default: true) }
    it { is_expected.to have_db_column(:left_nav_section).of_type(:string) }
    it { is_expected.to have_db_column(:collapsed_nav_sections).with_options(null: false, default: []) }
  end

  # ── Defaults ──────────────────────────────────────────────────────────────
  describe "Defaults" do
    it "starts with the nav visible and nothing collapsed" do
      session = create(:session)
      expect(session.left_nav_visible).to be true
      expect(session.collapsed_nav_sections).to eq([])
      expect(session.left_nav_section).to be_nil
    end
  end

  # ── #sync_left_nav_section! ────────────────────────────────────────────────
  describe "#sync_left_nav_section!" do
    # 1) Happy Path ─────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "records the section on first sync" do
        session = create(:session)
        session.sync_left_nav_section!(:blog_posts)
        expect(session.reload.left_nav_section).to eq("blog_posts")
      end
    end

    # 3) Alternative Paths ────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "accepts a symbol or a string interchangeably" do
        session = create(:session)
        session.sync_left_nav_section!(:blog_posts)
        expect { session.sync_left_nav_section!("blog_posts") }.not_to change { session.reload.left_nav_section }
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "forces the nav visible again when the section changes" do
        session = create(:session, left_nav_visible: false, left_nav_section: "event_tracker")
        session.sync_left_nav_section!(:blog_posts)
        expect(session.reload.left_nav_visible).to be true
        expect(session.left_nav_section).to eq("blog_posts")
      end

      it "leaves visibility untouched when the section is unchanged" do
        session = create(:session, left_nav_visible: false, left_nav_section: "blog_posts")
        session.sync_left_nav_section!(:blog_posts)
        expect(session.reload.left_nav_visible).to be false
      end
    end
  end

  # ── #toggle_left_nav_visibility! ───────────────────────────────────────────
  describe "#toggle_left_nav_visibility!" do
    # 3) Alternative Paths ────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "flips visible to hidden and back again" do
        session = create(:session)
        session.toggle_left_nav_visibility!
        expect(session.reload.left_nav_visible).to be false
        session.toggle_left_nav_visibility!
        expect(session.reload.left_nav_visible).to be true
      end
    end
  end

  # ── #left_nav_section_collapsed? / #toggle_left_nav_section! ─────────────
  describe "#toggle_left_nav_section!" do
    # 1) Happy Path ─────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "collapses a section that wasn't collapsed" do
        session = create(:session)
        session.toggle_left_nav_section!("blog_posts:views")
        expect(session.reload.left_nav_section_collapsed?("blog_posts:views")).to be true
      end

      it "expands a section that was collapsed" do
        session = create(:session, collapsed_nav_sections: [ "blog_posts:views" ])
        session.toggle_left_nav_section!("blog_posts:views")
        expect(session.reload.left_nav_section_collapsed?("blog_posts:views")).to be false
      end
    end

    # 4) Edge Cases ────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "toggling one section never affects another, including across apps" do
        session = create(:session, collapsed_nav_sections: [ "blog_posts:views" ])
        session.toggle_left_nav_section!("event_tracker:views")
        expect(session.reload.left_nav_section_collapsed?("blog_posts:views")).to be true
        expect(session.left_nav_section_collapsed?("event_tracker:views")).to be true
        expect(session.left_nav_section_collapsed?("blog_posts:actions")).to be false
      end
    end
  end
end
