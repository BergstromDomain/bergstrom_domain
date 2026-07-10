require "rails_helper"

RSpec.describe "Events By Week", type: :feature do
  let(:today)      { Date.current }
  let(:week_start) { today.beginning_of_week }   # Monday
  let(:week_end)   { today.end_of_week }          # Sunday

  let!(:this_week_event) do
    create(:event,
      title: "Blackened Studio Session",
      year:  week_start.year,
      month: week_start.month,
      day:   week_start.day)
  end

  let!(:last_week_event) do
    last_monday = week_start - 7.days
    create(:event,
      title: "One Acoustic Rehearsal",
      year:  last_monday.year,
      month: last_monday.month,
      day:   last_monday.day)
  end

  let!(:next_week_event) do
    next_monday = week_end + 1.day
    create(:event,
      title: "Nothing Else Matters Recording",
      year:  next_monday.year,
      month: next_monday.month,
      day:   next_monday.day)
  end

  describe "Happy Path" do
    context "When 'Gary Guest' visits 'Events by week' with no date param" do
      before { visit events_by_week_path }

      it "Shows the current week heading" do
        expect(page).to have_selector("[data-testid='by-week-heading']",
          text: "#{week_start.strftime("%A %-d %B %Y")} - #{week_end.strftime("%A %-d %B %Y")}")
      end

      it "Shows events in the current week" do
        expect(page).to have_link("Blackened Studio Session")
      end

      it "Does not show events outside the current week" do
        expect(page).not_to have_link("One Acoustic Rehearsal")
        expect(page).not_to have_link("Nothing Else Matters Recording")
      end

      it "Shows previous week and next week navigation links" do
        expect(page).to have_selector("[data-testid='nav-previous-week']")
        expect(page).to have_selector("[data-testid='nav-next-week']")
      end
    end

    context "When 'Gary Guest' visits with a specific date param" do
      it "Shows events in the week containing that date" do
        last_monday = week_start - 7.days

        visit events_by_week_path(date: last_monday.iso8601)

        expect(page).to have_link("One Acoustic Rehearsal")
        expect(page).not_to have_link("Blackened Studio Session")
      end
    end

    context "When 'Gary Guest' clicks the previous week link" do
      it "Navigates to the previous week" do
        visit events_by_week_path

        find("[data-testid='nav-previous-week']").click

        expect(page).to have_link("One Acoustic Rehearsal")
      end
    end

    context "When 'Gary Guest' clicks the next week link" do
      it "Navigates to the next week" do
        visit events_by_week_path

        find("[data-testid='nav-next-week']").click

        expect(page).to have_link("Nothing Else Matters Recording")
      end
    end
  end

  describe "Negative Path" do
    context "When there are no events in the selected week" do
      it "Shows an empty state message" do
        empty_week = week_start + 60.days

        visit events_by_week_path(date: empty_week.iso8601)

        expect(page).to have_selector("[data-testid='no-events-message']")
        expect(page).not_to have_selector("[data-testid='event-list']")
      end
    end
  end

  describe "Alternative Path" do
    context "When 'Uno User' is signed in" do
      let(:uno) { create(:user) }

      before { sign_in_as(uno) }

      it "Shows the current week while authenticated" do
        visit events_by_week_path

        expect(page).to have_selector("[data-testid='by-week-heading']")
        expect(page).to have_link("Blackened Studio Session")
      end
    end
  end

  describe "Edge Cases" do
    context "When an invalid date param is passed" do
      it "Falls back to the current week without raising an error" do
        visit events_by_week_path(date: "garbage")

        expect(page).to have_selector("[data-testid='by-week-heading']",
          text: "#{week_start.strftime("%A %-d %B %Y")} - #{week_end.strftime("%A %-d %B %Y")}")
      end
    end

    context "When the week spans December and January" do
      let(:dec_29) { Date.new(Date.current.year, 12, 29) }
      let(:jan_4)  { dec_29 + 6.days }

      let!(:dec_event) do
        create(:event,
          title: "Metallica New Year Eve Concert",
        month: 12,
        day:   29,
        year:  Date.current.year)
      end

      let!(:jan_event) do
        create(:event,
          title: "Metallica New Year Day Show",
          month: 1,
          day:   3,
          year:  Date.current.year + 1)
        end

        it "Shows events from both December and January in the same week" do
            visit events_by_week_path(date: dec_29.iso8601)

            expect(page).to have_link("Metallica New Year Eve Concert")
            expect(page).to have_link("Metallica New Year Day Show")
        end

        it "Does not show events with a day outside the week's day range" do
        create(:event, title: "Outside The Week Event", month: 1, day: 28, year: Date.current.year)

        visit events_by_week_path(date: dec_29.iso8601)

        expect(page).not_to have_link("Outside The Week Event")
        end
    end

    context "When an event in range has no year" do
      let(:monday) { Date.current.beginning_of_week }

      it "Shows the event, matching by month and day like the day and month views do" do
        create(:event, :no_year, title: "Undated Recurring Event",
          month: monday.month, day: monday.day)

        visit events_by_week_path

        expect(page).to have_link("Undated Recurring Event")
      end
    end
  end
end
