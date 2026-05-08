require "rails_helper"

RSpec.describe "Events By Day", type: :feature do
  let(:today)     { Date.current }
  let(:yesterday) { today - 1.day }
  let(:tomorrow)  { today + 1.day }

  let!(:todays_event) do
    create(:event,
      title: "Master of Puppets Recording Session",
      month: today.month,
      day:   today.day,
      year:  today.year)
  end

  let!(:same_day_different_year) do
    create(:event,
      title: "Cliff Burton Joins Metallica",
      month: today.month,
      day:   today.day,
      year:  1982)
  end

  let!(:yesterdays_event) do
    create(:event,
      title: "Fade to Black Rehearsal",
      month: yesterday.month,
      day:   yesterday.day,
      year:  yesterday.year)
  end

  let!(:tomorrows_event) do
    create(:event,
      title: "Battery Live Performance",
      month: tomorrow.month,
      day:   tomorrow.day,
      year:  tomorrow.year)
  end

  describe "Happy Path" do
    context "When 'Gary Guest' visits 'Events by day' with no date param" do
      before { visit events_by_day_path }

      it "Shows today's heading" do
        expect(page).to have_css("[data-testid='by-day-heading']",
          text: today.strftime("%A, %-d %B %Y"))
      end

      it "Shows events on today's date" do
        expect(page).to have_css("[data-testid='event-list']")
        expect(page).to have_link("Master of Puppets Recording Session")
      end

      it "Shows events from other years on the same day and month" do
        expect(page).to have_link("Cliff Burton Joins Metallica")
      end

      it "Does not show events from other days" do
        expect(page).not_to have_link("Fade to Black Rehearsal")
        expect(page).not_to have_link("Battery Live Performance")
      end

      it "Shows the previous day navigation link" do
        expect(page).to have_css("[data-testid='nav-previous-day']")
      end

      it "Shows the next day navigation link" do
        expect(page).to have_css("[data-testid='nav-next-day']")
      end
    end

    context "When 'Gary Guest' visits with a specific date param" do
      before { visit events_by_day_path(date: yesterday.iso8601) }

      it "Shows the correct heading for that date" do
        expect(page).to have_css("[data-testid='by-day-heading']",
          text: yesterday.strftime("%A, %-d %B %Y"))
      end

      it "Shows events on that date" do
        expect(page).to have_link("Fade to Black Rehearsal")
      end

      it "Does not show events from other dates" do
        expect(page).not_to have_link("Master of Puppets Recording Session")
        expect(page).not_to have_link("Battery Live Performance")
      end
    end

    context "When 'Gary Guest' clicks the previous day link" do
      it "Navigates to the previous day" do
        visit events_by_day_path

        find("[data-testid='nav-previous-day']").click

        expect(page).to have_css("[data-testid='by-day-heading']",
          text: yesterday.strftime("%A, %-d %B %Y"))
      end
    end

    context "When 'Gary Guest' clicks the next day link" do
      it "Navigates to the next day" do
        visit events_by_day_path

        find("[data-testid='nav-next-day']").click

        expect(page).to have_css("[data-testid='by-day-heading']",
          text: tomorrow.strftime("%A, %-d %B %Y"))
      end
    end
  end

  describe "Negative Path" do
    context "When there are no events on the selected day" do
      it "Shows an empty state message" do
        empty_day = today + 30.days

        visit events_by_day_path(date: empty_day.iso8601)

        expect(page).to have_css("[data-testid='no-events-message']")
        expect(page).not_to have_css("[data-testid='event-list']")
      end
    end
  end

  describe "Alternative Path" do
    context "When 'Uno User' is signed in" do
      let(:uno) { create(:user) }

      before { sign_in_as(uno) }

      it "Shows today's events while authenticated" do
        visit events_by_day_path

        expect(page).to have_css("[data-testid='by-day-heading']")
        expect(page).to have_link("Master of Puppets Recording Session")
      end
    end
  end

  describe "Edge Cases" do
    context "When an invalid date param is passed" do
      it "Falls back to today without raising an error" do
        visit events_by_day_path(date: "not-a-date")

        expect(page).to have_css("[data-testid='by-day-heading']",
          text: today.strftime("%A, %-d %B %Y"))
      end
    end
  end
end
