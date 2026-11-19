# spec/features/dossier/timeline_spec.rb
require "rails_helper"

RSpec.describe "Dossier Timeline", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  # Titled on the Timeline by its employer, named after it here.
  def engagement(title, start_month, end_month, **attributes)
    create(:dossier_engagement, user: charlie, position_title: title, employer: create(:dossier_organisation, name: title),
                                start_month: start_month, end_month: end_month, **attributes)
  end

  # Bench time is a permanent job's only; without its own Assignment, so
  # the test chooses what the Assignments cover.
  def permanent(title, start_month, end_month)
    engagement(title, start_month, end_month, employment_type: create(:dossier_employment_type, :permanent))
      .tap { |job| job.assignments.each(&:destroy!) }
  end

  def assignment(job, project, start_month, end_month)
    create(:dossier_assignment, engagement: job, project: project, start_month: start_month, end_month: end_month,
                                client: create(:dossier_organisation, name: "Client #{project}"))
  end

  # The rows of a list, top to bottom: Assignments by project, bench by label.
  def rows(within_selector)
    find(within_selector).all(".dossier-assignment-list > li").map do |row|
      row.find("a", match: :first).text
    end
  end

  # PinnacleQM's shape: a contract with EIP, then TMR, and Hudson between them.
  def split_contract
    contract = engagement("PinnacleQM", "2018-11", "2023-01")
    assignment(contract, "EIP", "2018-11", "2019-08")
    assignment(contract, "TMR", "2020-09", "2023-01")
    engagement("Hudson", "2019-12", "2020-09")
    contract
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the gap between two Engagements and bench time inside one" do
      engagement("Older", "2015-01", "2017-12")
      newer = permanent("Newer", "2018-06", "2022-06")
      create(:dossier_assignment, engagement: newer, start_month: "2018-06", end_month: "2020-01",
                                  client: create(:dossier_organisation, name: "APA Group"), project: "Market Services")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).to have_css("[data-testid='timeline'] [data-testid='engagement-card']", count: 2)
      within("[data-testid='timeline-gap']") do
        expect(page).to have_selector("[data-testid='timeline-gap-label']", exact_text: "Gap · 5 months")
        expect(page).to have_selector(".dossier-assignment-row__dates", exact_text: "Jan 2018 – May 2018")
      end
      within("[data-testid='engagement-card']", text: "Newer") do
        expect(page).to have_selector("[data-testid='engagement-type']", exact_text: newer.employment_type.name)
        expect(page).to have_selector("[data-testid='engagement-dates']", exact_text: "Jun 2018 – Jun 2022")
        expect(page).to have_selector("[data-testid='assignment-row']", text: "APA Group - Market Services")
        within("[data-testid='timeline-bench']") do
          expect(page).to have_selector("[data-testid='timeline-bench-label']", exact_text: "Bench · 2+ years")
          expect(page).to have_selector(".dossier-assignment-row__dates", exact_text: "Feb 2020 – Jun 2022")
        end
      end
    end

    it "Opens a bench period, showing the Engagement it falls in" do
      newer = permanent("Newer", "2018-06", "2022-06")
      create(:dossier_assignment, engagement: newer, start_month: "2018-06", end_month: "2020-01")
      sign_in_as(charlie)
      visit dossier_engagements_path
      click_link "Bench · 2+ years"

      expect(page).to have_selector("h1.page-title", text: "Bench")
      expect(page).to have_selector("[data-testid='period-dates']", text: "Feb 2020 – Jun 2022")
      expect(page).to have_selector("[data-testid='period-duration']", text: "2+ years")
      expect(page).to have_link(newer.to_toast_label, href: dossier_engagement_path(newer))
      click_link "Back"
      expect(page).to have_current_path(dossier_engagements_path)
    end

    it "Opens a gap period" do
      engagement("Older", "2015-01", "2017-12")
      engagement("Newer", "2018-06", "2022-06")
      sign_in_as(charlie)
      visit dossier_engagements_path
      click_link "Gap · 5 months"

      expect(page).to have_selector("h1.page-title", text: "Gap")
      expect(page).to have_selector("[data-testid='period-dates']", text: "Jan 2018 – May 2018")
      expect(page).not_to have_selector("[data-testid='period-engagement']")
      expect(page).to have_selector("[data-testid='period-credentials-empty']")
    end

    it "Lists every Credential completed during a period, of any type, and none from outside it" do
      engagement("Older", "2015-01", "2017-12")
      engagement("Newer", "2018-06", "2022-06")
      create(:dossier_credential, user: charlie, title: "Scrum: The Basics", start_month: "2018-01", end_month: "2018-01")
      create(:dossier_credential, :certification, user: charlie, title: "Certified ScrumMaster",
                                                  start_month: "2018-05", end_month: "2018-05", end_day: "31")
      create(:dossier_credential, user: charlie, title: "Before The Gap", start_month: "2017-12", end_month: "2017-12")
      create(:dossier_credential, user: charlie, title: "After The Gap", start_month: "2018-06", end_month: "2018-06")
      create(:dossier_credential, user: charlie, title: "Still Taking It", start_month: "2018-02", end_month: "")
      create(:dossier_credential, title: "Someone Else's Course", start_month: "2018-03", end_month: "2018-03")
      sign_in_as(charlie)
      visit dossier_period_path(from: "2018-01-01", to: "2018-05-31")

      within("[data-testid='show-panel-courses']") do
        expect(all("[data-testid='training-title']").map(&:text)).to eq([ "Certified ScrumMaster", "Scrum: The Basics" ])
      end
    end
  end

  describe "Happy Path: career breaks, bench placement and split Engagements" do
    it "Shows a career break with its badge, the gap still beside it" do
      engagement("Tilgin", "2005-03", "2012-09")
      engagement("SMS", "2013-05", "2018-11")
      create(:dossier_engagement, :career_break, user: charlie, position_title: "Time off", start_month: "2012-10", end_month: "2013-04")
      sign_in_as(charlie)
      visit dossier_engagements_path

      within("[data-testid='engagement-card']", text: "Time off") do
        expect(page).to have_selector("[data-testid='engagement-title']", exact_text: "Time off")
        expect(page).to have_selector("[data-testid='engagement-career-break']", exact_text: "Career Break")
        expect(page).to have_selector("[data-testid='career-break-icon']")
      end
      expect(page).to have_selector("[data-testid='timeline-gap']", text: "Oct 2012 – Apr 2013")
    end

    it "Places a bench between the Assignments either side of it, on the Timeline and the Engagement page" do
      elysium = permanent("Elysium", "2024-09", "")
      assignment(elysium, "QPT", "2024-09", "2025-05")
      assignment(elysium, "DL", "2025-08", "") # a new Assignment goes on top
      sign_in_as(charlie)

      visit dossier_engagements_path
      expect(rows("[data-testid='engagement-card']")).to eq([ "Client DL - DL", "Bench · 2 months", "Client QPT - QPT" ])
      visit dossier_engagement_path(elysium)
      expect(rows("[data-testid='engagement-assignments']")).to eq([ "Client DL - DL", "Bench · 2 months", "Client QPT - QPT" ])
    end

    it "Splits a contract into two cards around another Engagement, the space before it a gap" do
      contract = split_contract
      sign_in_as(charlie)
      visit dossier_engagements_path

      cards = all("[data-testid='engagement-card']")
      expect(cards.map { |card| card.find("[data-testid='engagement-title']").text }).to eq(%w[PinnacleQM Hudson PinnacleQM])
      expect(cards.map { |card| card.find("[data-testid='engagement-dates']").text })
        .to eq([ "Sep 2020 – Jan 2023", "Dec 2019 – Sep 2020", "Nov 2018 – Aug 2019" ])
      expect(cards.first).to have_selector("[data-testid='assignment-row']", count: 1, text: "TMR")
      expect(cards.last).to have_selector("[data-testid='assignment-row']", count: 1, text: "EIP")
      expect(cards.first).to have_link("PinnacleQM", href: dossier_engagement_path(contract))
      expect(cards.last).to have_link("PinnacleQM", href: dossier_engagement_path(contract))

      click_link "Gap · 3 months"
      expect(page).to have_current_path(dossier_period_path(from: "2019-09-01", to: "2019-11-30"))
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

    it "Marks a personal Engagement and doesn't let it fill a gap or show bench time" do
      engagement("Older", "2015-01", "2017-12")
      engagement("Hobby App", "2018-01", "2018-05", employment_type: create(:dossier_employment_type, :personal))
      engagement("Newer", "2018-06", "2022-06")
      sign_in_as(charlie)
      visit dossier_engagements_path

      within("[data-testid='engagement-card']", text: "Hobby App") do
        expect(page).to have_selector("[data-testid='engagement-personal']", text: "Personal")
        expect(page).not_to have_selector("[data-testid='timeline-bench']")
      end
      expect(page).to have_selector("[data-testid='timeline-gap']", text: "Jan 2018 – May 2018")
    end

    it "Turns away a period that isn't on the Timeline" do
      engagement("Older", "2015-01", "2017-12")
      sign_in_as(charlie)
      visit dossier_period_path(from: "2018-01-01", to: "2018-05-31")

      expect(page).to have_current_path(dossier_engagements_path)
      expect(page).to have_content("That period isn't on your Timeline.")
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
    it "Keeps a contract as one card when nothing else falls between its Assignments" do
      contract = engagement("PinnacleQM", "2018-11", "2023-01")
      assignment(contract, "EIP", "2018-11", "2019-08")
      assignment(contract, "TMR", "2020-09", "2023-01")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).to have_selector("[data-testid='engagement-card']", count: 1)
      expect(page).to have_selector("[data-testid='assignment-row']", count: 2)
      expect(page).not_to have_selector("[data-testid='timeline-gap']")
    end

    it "Shows a permanent job without Assignments as one bench row" do
      permanent("Antenn", "2004-01", "2005-01")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(rows("[data-testid='engagement-card']")).to eq([ "Bench · 1+ year" ])
    end

    it "Shows no gap or bench rows for back-to-back, fully covered Engagements" do
      first = engagement("First", "2015-01", "2017-12")
      second = engagement("Second", "2018-01", "2022-06")
      create(:dossier_assignment, engagement: first)
      create(:dossier_assignment, engagement: second, systems_under_test_na: false, systems_under_test_text: "Ticketing platform")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).not_to have_selector("[data-testid='timeline-gap']")
      expect(page).not_to have_selector("[data-testid='timeline-bench']")
    end
  end
end
