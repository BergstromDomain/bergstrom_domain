require "rails_helper"

RSpec.describe "Events By Month", type: :feature do
  let(:today) { Date.current }

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

      it "Shows the current month heading" do
        expect(page).to have_selector("[data-testid='by-month-heading']",
          text: today.strftime("%B %Y"))
      end

      it "Shows events in the current month" do
        expect(page).to have_link("Orion Live Performance")
      end

      it "Does not show events from other months" do
        expect(page).not_to have_link("The Unforgiven Recording")
        expect(page).not_to have_link("Enter Sandman Soundcheck")
      end

      it "Shows previous and next month navigation links" do
        expect(page).to have_selector("[data-testid='nav-previous-month']")
        expect(page).to have_selector("[data-testid='nav-next-month']")
      end
    end

    context "When 'Gary Guest' visits with year and month params" do
      it "Shows events in the specified month" do
        last = today.beginning_of_month - 1.day

        visit events_by_month_path(year: last.year, month: last.month)

        expect(page).to have_link("The Unforgiven Recording")
        expect(page).not_to have_link("Orion Live Performance")
      end
    end

    context "When 'Gary Guest' clicks the previous month link" do
      it "Navigates to the previous month" do
        visit events_by_month_path

        find("[data-testid='nav-previous-month']").click

        expect(page).to have_link("The Unforgiven Recording")
      end
    end

    context "When 'Gary Guest' clicks the next month link" do
      it "Navigates to the next month" do
        visit events_by_month_path

        find("[data-testid='nav-next-month']").click

        expect(page).to have_link("Enter Sandman Soundcheck")
      end
    end
  end

  describe "Negative Path" do
    context "When there are no events in the selected month" do
      it "Shows an empty state message" do
        visit events_by_month_path(year: 2050, month: 1)

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

        expect(page).to have_selector("[data-testid='by-month-heading']")
        expect(page).to have_link("Orion Live Performance")
      end
    end
  end

  describe "Edge Cases" do
    context "When invalid year and month params are passed" do
      it "Falls back to the current month without raising an error" do
        visit events_by_month_path(year: "abc", month: "xyz")

        expect(page).to have_selector("[data-testid='by-month-heading']",
          text: today.strftime("%B %Y"))
      end
    end

    context "When month 13 is passed" do
      it "Falls back to the current month without raising an error" do
        visit events_by_month_path(year: today.year, month: 13)

        expect(page).to have_selector("[data-testid='by-month-heading']",
          text: today.strftime("%B %Y"))
      end
    end

    context "When navigating from December to next month" do
        it "Navigates to January" do
            visit events_by_month_path(year: Date.current.year, month: 12)
            find("[data-testid='nav-next-month']").click
            expect(page).to have_selector("[data-testid='by-month-heading']",
            text: "January #{Date.current.year + 1}")
        end
    end

    context "When navigating from January to previous month" do
        it "Navigates to December" do
            visit events_by_month_path(year: Date.current.year, month: 1)
            find("[data-testid='nav-previous-month']").click
            expect(page).to have_selector("[data-testid='by-month-heading']",
            text: "December #{Date.current.year - 1}")
        end
    end
  end
end
