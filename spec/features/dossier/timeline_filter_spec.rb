# spec/features/dossier/timeline_filter_spec.rb
require "rails_helper"

# The Timeline's Professional and Personal ticks, both on by default, kept per
# user in their Dossier settings. Gaps are worked out from Professional
# Engagements whatever is ticked, and hidden with Professional.
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

  def cards = all("[data-testid='engagement-card'] [data-testid='engagement-title']").map(&:text)
  def box(kind) = find("[data-testid='timeline-filter-#{kind}']")

  def visit_timeline_as(user)
    sign_in_as(user)
    visit dossier_engagements_path
  end

  # What the auto-submitting form sends: the blank keeps an all-unticked
  # submission apart from no submission at all.
  def filter(*kinds) = visit(dossier_engagements_path(kinds: [ "", *kinds.map(&:to_s) ]))

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows Charlie both kinds ticked, and hides Personal Engagements when Personal is unticked, keeping the gap", js: true do
      sign_in_and_settle(charlie)
      visit dossier_engagements_path
      expect([ box(:professional), box(:personal) ]).to all(be_checked)
      expect(page).to have_selector("[data-testid='engagement-title']", text: hobby.to_toast_label)

      box(:personal).uncheck

      expect(page).to have_no_selector("[data-testid='engagement-title']", text: hobby.to_toast_label)
      expect(cards).to eq([ newer.to_toast_label, older.to_toast_label ])
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

      expect(cards).to eq([ newer.to_toast_label, older.to_toast_label ])
      expect(box(:personal)).not_to be_checked
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows only Personal Engagements, without gaps, when Professional is unticked" do
      sign_in_as(charlie)
      filter(:personal)

      expect(cards).to eq([ hobby.to_toast_label ])
      expect(page).not_to have_selector("[data-testid='timeline-gap']")
    end

    it "Remembers Charlie's ticks on the next visit" do
      sign_in_as(charlie)
      filter(:professional)
      visit dossier_path
      visit dossier_engagements_path

      expect(box(:personal)).not_to be_checked
      expect(cards).not_to include(hobby.to_toast_label)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps each user's ticks apart" do
      chris_hobby = engagement("Hobby", "2020-01", "2021-01", user: chris, trait: :personal)
      charlie.app_settings_for("dossier").update!(timeline_personal: false)
      visit_timeline_as(chris)

      expect(box(:personal)).to be_checked
      expect(cards).to eq([ chris_hobby.to_toast_label ])
    end
  end
end
