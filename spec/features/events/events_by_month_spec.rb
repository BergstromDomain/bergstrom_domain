require "rails_helper"

RSpec.describe "Events By Month", type: :feature do
  let(:today) { Date.current }

  # A month at least 6 away from today's month in either direction, so it
  # never collides with today/previous/next month's factory events below.
  let(:safe_month) { ((today.month + 5) % 12) + 1 }

  let!(:this_month_event) do
    create(:event,
      title: "Orion Live Performance",
      year:  today.year,
      month: today.month,
      day:   1)
  end

  let!(:last_month_event) do
    last = today.beginning_of_month - 1.day
    create(:event,
      title: "The Unforgiven Recording",
      year:  last.year,
      month: last.month,
      day:   1)
  end

  let!(:next_month_event) do
    nxt = today.end_of_month + 1.day
    create(:event,
      title: "Enter Sandman Soundcheck",
      year:  nxt.year,
      month: nxt.month,
      day:   1)
  end

  describe "Happy Path" do
    context "When 'Gary Guest' visits 'Events by month' with no params" do
      before { visit events_by_month_path }

      it "Highlights the current month in the tab bar" do
        expect(page).to have_selector(
          "[data-testid='month-nav-link'].month-nav__link--active",
          text: today.strftime("%b")
        )
      end

      it "Shows events in the current month" do
        expect(page).to have_link("Orion Live Performance")
      end

      it "Does not show events from other months" do
        expect(page).not_to have_link("The Unforgiven Recording")
        expect(page).not_to have_link("Enter Sandman Soundcheck")
      end

      it "Shows the month tab navigation bar" do
        expect(page).to have_selector("[data-testid='month-nav']")
        expect(page).to have_selector("[data-testid='month-nav-all']")
        expect(page).to have_selector("[data-testid='month-nav-link']", count: 12)
      end

      it "Does not show a previous/next month navigation row" do
        expect(page).not_to have_selector("[data-testid='nav-previous-month']")
        expect(page).not_to have_selector("[data-testid='nav-next-month']")
      end
    end

    context "When 'Gary Guest' visits with a month param" do
      it "Shows events in the specified month, regardless of the event's year" do
        last = today.beginning_of_month - 1.day

        visit events_by_month_path(month: last.month)

        expect(page).to have_link("The Unforgiven Recording")
        expect(page).not_to have_link("Orion Live Performance")
      end

      it "Highlights the requested month's tab" do
        visit events_by_month_path(month: 6)

        expect(page).to have_selector(
          "[data-testid='month-nav-link'].month-nav__link--active",
          text: "Jun"
        )
      end
    end

    context "When clicking a month tab" do
      it "Navigates to that month" do
        visit events_by_month_path

        click_link Date::ABBR_MONTHNAMES[safe_month]

        expect(page).to have_selector(
          "[data-testid='month-nav-link'].month-nav__link--active",
          text: Date::ABBR_MONTHNAMES[safe_month]
        )
      end
    end
  end

  describe "Negative Path" do
    context "When there are no events in the selected month" do
      it "Shows an empty state message" do
        visit events_by_month_path(month: safe_month)

        expect(page).to have_selector("[data-testid='no-events-message']")
        expect(page).not_to have_selector("[data-testid='event-list']")
      end
    end
  end

  describe "Alternative Path" do
    context "When 'Uno User' is signed in" do
      let(:uno) { create(:user) }

      before { sign_in_as(uno) }

      it "Shows the current month while authenticated" do
        visit events_by_month_path

        expect(page).to have_link("Orion Live Performance")
      end
    end
  end

  describe "Edge Cases" do
    context "When an invalid month param is passed" do
      it "Falls back to the current month without raising an error" do
        visit events_by_month_path(month: "xyz")

        expect(page).to have_selector(
          "[data-testid='month-nav-link'].month-nav__link--active",
          text: today.strftime("%b")
        )
      end
    end

    context "When month 13 is passed" do
      it "Falls back to the current month without raising an error" do
        visit events_by_month_path(month: 13)

        expect(page).to have_selector(
          "[data-testid='month-nav-link'].month-nav__link--active",
          text: today.strftime("%b")
        )
      end
    end

    context "When a year param is passed" do
      it "Is ignored — the same month's events show regardless of year" do
        visit events_by_month_path(month: today.month, year: 1999)

        expect(page).to have_link("Orion Live Performance")
      end
    end
  end
end
