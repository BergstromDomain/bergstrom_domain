# spec/features/dossier/timeline_filter_spec.rb
require "rails_helper"

# The Timeline's Professional and Personal ticks, both on by default, and its
# Hide Gaps tick, off by default, kept per user in their Dossier settings. Gaps
# are worked out from Professional Engagements whatever is ticked, and hidden
# with Professional. Hide Gaps hides the gaps and every bench row.
RSpec.describe "Dossier Timeline filter", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let!(:older) { engagement("Test Analyst", "2015-01", "2017-12") }
  let!(:newer) { engagement("Test Manager", "2018-06", "2022-06") }
  let!(:hobby) { engagement("Web Developer", "2016-01", "2023-12", trait: :personal) }

  def engagement(title, start_month, end_month, user: charlie, trait: nil)
    create(:dossier_engagement, *[ trait ].compact, user: user, position_title: title,
                                                    start_month: start_month, end_month: end_month)
  end

  # A permanent job with one Assignment in its middle: bench either side.
  def benched
    job = engagement("Test Lead", "2023-01", "2023-12", trait: :permanent).tap { |e| e.assignments.each(&:destroy!) }
    create(:dossier_assignment, engagement: job, start_month: "2023-04", end_month: "2023-08")
    job
  end

  def cards = all("[data-testid='engagement-card'] [data-testid='engagement-title']").map(&:text)
  def box(kind) = find("[data-testid='timeline-filter-#{kind}']")

  def visit_timeline_as(user)
    sign_in_as(user)
    visit dossier_engagements_path
  end

  # What the auto-submitting form sends: the blank keeps an all-unticked
  # submission apart from no submission at all.
  def filter(*kinds, hide_gaps: false)
    visit(dossier_engagements_path(kinds: [ "", *kinds.map(&:to_s) ], hide_gaps: (hide_gaps ? "1" : nil)))
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows Charlie both kinds ticked, and hides Personal Engagements when Personal is unticked, keeping the gap", js: true do
      sign_in_and_settle(charlie)
      visit dossier_engagements_path
      expect([ box(:professional), box(:personal) ]).to all(be_checked)
      expect(page).to have_selector("[data-testid='engagement-title']", text: hobby.heading)

      box(:personal).uncheck

      expect(page).to have_no_selector("[data-testid='engagement-title']", text: hobby.heading)
      expect(cards).to eq([ newer.heading, older.heading ])
      expect(page).to have_selector("[data-testid='timeline-gap-label']", exact_text: "Gap · 5 months")
    end

    it "Lines the ticks up on the left, under the header", js: true do
      sign_in_and_settle(charlie)
      visit dossier_engagements_path

      offset = page.evaluate_script(<<~JS)
        (() => {
          const form = document.querySelector("[data-testid='timeline-filter']");
          const first = form.querySelector('.form-check');
          return first.getBoundingClientRect().left - form.getBoundingClientRect().left;
        })()
      JS
      expect(offset).to be < 2
    end

    it "Hides the gaps and bench rows when Charlie ticks Hide Gaps, keeping the Engagements and Assignments", js: true do
      benched
      sign_in_and_settle(charlie)
      visit dossier_engagements_path
      expect(box(:hide_gaps)).not_to be_checked
      expect(page).to have_selector("[data-testid='timeline-gap']")
      expect(page).to have_selector("[data-testid='timeline-bench']", count: 2)

      box(:hide_gaps).check

      expect(page).to have_no_selector("[data-testid='timeline-bench']")
      expect(page).to have_no_selector("[data-testid='timeline-gap']")
      expect(cards.size).to eq(4)
      expect(page).to have_selector("[data-testid='assignment-row']", count: 1)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows the empty state with both unticked" do
      sign_in_as(charlie)
      filter

      expect(page).to have_selector("[data-testid='timeline-filtered-empty']")
      expect(page).not_to have_selector("[data-testid='engagement-card']")
      expect(page).to have_selector("[data-testid='timeline-filter']")
    end

    it "Ignores an unknown kind" do
      sign_in_as(charlie)
      filter(:professional, :bogus)

      expect(cards).to eq([ newer.heading, older.heading ])
      expect(box(:personal)).not_to be_checked
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows only Personal Engagements, without gaps, when Professional is unticked" do
      sign_in_as(charlie)
      filter(:personal)

      expect(cards).to eq([ hobby.heading ])
      expect(page).not_to have_selector("[data-testid='timeline-gap']")
    end

    it "Shows a career break with Professional, not Personal" do
      create(:dossier_engagement, :career_break, user: charlie, position_title: "Time off", start_month: "2018-01", end_month: "2018-05")
      sign_in_as(charlie)

      filter(:professional)
      expect(cards).to include("Time off")
      filter(:personal)
      expect(cards).not_to include("Time off")
    end

    it "Remembers Charlie's ticks on the next visit" do
      sign_in_as(charlie)
      filter(:professional)
      visit dossier_path
      visit dossier_engagements_path

      expect(box(:personal)).not_to be_checked
      expect(cards).not_to include(hobby.heading)
    end

    it "Remembers Hide Gaps on the next visit, and shows them again once unticked" do
      benched
      sign_in_as(charlie)
      filter(:professional, :personal, hide_gaps: true)
      visit dossier_engagements_path

      expect(box(:hide_gaps)).to be_checked
      expect(page).not_to have_selector("[data-testid='timeline-bench']")
      expect(page).not_to have_selector("[data-testid='timeline-gap']")

      filter(:professional, :personal)
      expect(box(:hide_gaps)).not_to be_checked
      expect(page).to have_selector("[data-testid='timeline-bench']", count: 2)
      expect(page).to have_selector("[data-testid='timeline-gap']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps each user's ticks apart" do
      chris_hobby = engagement("Hobby", "2020-01", "2021-01", user: chris, trait: :personal)
      charlie.app_settings_for("dossier").update!(timeline_personal: false)
      visit_timeline_as(chris)

      expect(box(:personal)).to be_checked
      expect(cards).to eq([ chris_hobby.heading ])
    end

    it "Keeps the bench on the Engagement's own page with Hide Gaps ticked" do
      job = benched
      charlie.app_settings_for("dossier").update!(timeline_hide_gaps: true)
      sign_in_as(charlie)
      visit dossier_engagement_path(job)

      expect(page).to have_selector("[data-testid='timeline-bench']", count: 2)
    end
  end
end
