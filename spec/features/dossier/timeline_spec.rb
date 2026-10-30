# spec/features/dossier/timeline_spec.rb
require "rails_helper"

RSpec.describe "Dossier Timeline", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  def engagement(title, start_month, end_month, **attributes)
    create(:dossier_engagement, user: charlie, position_title: title, start_month: start_month, end_month: end_month, **attributes)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the gap between two Engagements and bench time inside one" do
      engagement("Older", "2015-01", "2017-12")
      newer = engagement("Newer", "2018-06", "2022-06")
      create(:dossier_assignment, engagement: newer, start_month: "2018-06", end_month: "2020-01")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).to have_selector("[data-testid='timeline-gap']", text: "Gap · Jan 2018 – May 2018 · 5 months")
      within("[data-testid='engagement-card']", text: "Newer") do
        within("[data-testid='timeline-bench']") do
          expect(page).to have_selector("[data-testid='timeline-bench-label']", exact_text: "Bench · 2+ years")
          expect(page).to have_selector(".dossier-assignment-row__dates", exact_text: "Feb 2020 – Jun 2022")
        end
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves deleted Engagements out, so they don't hide a gap" do
      engagement("Older", "2015-01", "2017-12")
      engagement("Middle", "2018-01", "2018-05").soft_delete!
      engagement("Newer", "2018-06", "2022-06")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).not_to have_content("Middle")
      expect(page).to have_selector("[data-testid='timeline-gap']", text: "Jan 2018 – May 2018")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Flags an Assignment whose Tech Stack is entirely N/A as incomplete" do
      engagement("Permanent Job", "2019-01", "2020-12", employment_type: create(:dossier_employment_type, :permanent))
      sign_in_as(charlie)
      visit dossier_engagements_path

      within("[data-testid='assignment-row']") do
        expect(page).to have_selector("[data-testid='tech-stack-incomplete']", text: "Tech Stack Incomplete")
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows no gap or bench rows for back-to-back, fully covered Engagements" do
      first = engagement("First", "2015-01", "2017-12")
      second = engagement("Second", "2018-01", "2022-06")
      create(:dossier_assignment, engagement: first)
      create(:dossier_assignment, engagement: second, system_under_test: "Ticketing platform")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).not_to have_selector("[data-testid='timeline-gap']")
      expect(page).not_to have_selector("[data-testid='timeline-bench']")
    end
  end
end
