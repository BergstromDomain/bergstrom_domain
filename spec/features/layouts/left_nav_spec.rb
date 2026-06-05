require "rails_helper"

RSpec.describe "Left Navigation", type: :feature do
  # ── Static pages — left nav must never appear ──────────────────────────────

  describe "Static Pages" do
    let(:uno) { create(:user) }

    before { sign_in_as(uno) }

    it "Is not present on the 'Home' page" do
      visit root_path
      expect(page).not_to have_selector("[data-testid='left-nav']")
    end

    it "Is not present on the 'About' page" do
      visit about_path
      expect(page).not_to have_selector("[data-testid='left-nav']")
    end

    it "Is not present on the 'Contact' page" do
      visit contact_path
      expect(page).not_to have_selector("[data-testid='left-nav']")
    end

    it "Is not present on the 'Blog Posts' page" do
      visit blog_posts_path
      expect(page).not_to have_selector("[data-testid='left-nav']")
    end
  end

  # ── Happy Path ─────────────────────────────────────────────────────────────

  describe "Happy Path" do
    context "When 'Gary Guest' visits the 'Events' index" do
      before { visit events_path }

      it "Shows the left nav" do
        expect(page).to have_selector("[data-testid='left-nav']")
      end

      it "Shows the 'Views H2' header" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-views-h2']")
        end
      end

      it "Shows the 'Event Tracker' group and link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-event-tracker-h3']")
          expect(page).to have_link("Event Tracker", href: event_tracker_path)
        end
      end

      it "Shows the 'Events' group with calendar links" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-events-h3']")
          expect(page).to have_link("Events by day",   href: events_by_day_path)
          expect(page).to have_link("Events by week",  href: events_by_week_path)
          expect(page).to have_link("Events by month", href: events_by_month_path)
        end
      end

      it "Shows the 'People' group and link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-people-h3']")
          expect(page).to have_link("People", href: people_path)
        end
      end

      it "Shows the 'Event Type' group and link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-event-type-h3']")
          expect(page).to have_link("Event Types", href: event_types_path)
        end
      end

      it "Shows the 'How To' section with 'User Guide' link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-how-to-h2']")
          expect(page).to have_link("User Guide", href: user_guide_path)
        end
      end

      it "Does not show the 'Actions' section" do
        within("[data-testid='left-nav']") do
          expect(page).not_to have_selector("[data-testid='left-nav-actions-h2']")
          expect(page).not_to have_link("Create Event")
          expect(page).not_to have_link("Create Person")
          expect(page).not_to have_link("Create Event Type")
        end
      end

      it "Does not show the 'Import & Export' section" do
        within("[data-testid='left-nav']") do
          expect(page).not_to have_selector("[data-testid='left-nav-import-export-h2']")
        end
      end
    end

    context "When 'Uno User' is signed in and visits the 'Events' index" do
      let(:uno) { create(:user) }

      before do
        sign_in_as(uno)
        visit events_path
      end

      it "Shows the left nav" do
        expect(page).to have_selector("[data-testid='left-nav']")
      end

      it "Shows the 'Views' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-views-h2']")
        end
      end

      it "Does not show the 'Actions' section" do
        within("[data-testid='left-nav']") do
          expect(page).not_to have_selector("[data-testid='left-nav-actions-h2']")
        end
      end

      it "Does not show the 'Import & Export' section" do
        within("[data-testid='left-nav']") do
          expect(page).not_to have_selector("[data-testid='left-nav-import-export-h2']")
        end
      end
    end

    context "When 'Charlie Content Creator' is signed in and visits the 'Events' index" do
      let(:charlie) { create(:user, :content_creator) }

      before do
        sign_in_as(charlie)
        visit events_path
      end

      it "Shows the 'Actions H2' header" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-actions-h2']")
        end
      end

      it "Shows the 'Create Event' link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_link("Create Event", href: new_event_path)
        end
      end

      it "Shows the 'Create Person' link" do
        within("[data-testid='left-nav']") do
          expect(page).to have_link("Create Person", href: new_person_path)
        end
      end

      it "Does not shows the Create Event Type link" do
        within("[data-testid='left-nav']") do
          expect(page).not_to have_link("Create Event Type", href: new_event_type_path)
        end
      end

      it "Shows the 'Import & Export' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-import-export-h2']")
          expect(page).to have_link("Import People and Events",   href: import_export_path)
          expect(page).to have_link("Download People and Events", href: import_export_path)
        end
      end
    end

    context "When the 'Event Types' index is visited" do
      let(:uno) { create(:user) }

      before do
        sign_in_as(uno)
        visit event_types_path
      end

      it "Shows the left nav" do
        expect(page).to have_selector("[data-testid='left-nav']")
      end

      it "Shows the 'Views' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-views-h2']")
        end
      end
    end
  end

  # ── Alternative Path ───────────────────────────────────────────────────────

  describe "Alternative Path" do
    context "When 'Gary Guest' clicks the 'Event Tracker' link" do
      it "Navigates to the 'Event Tracker' stub page" do
        visit events_path
        within("[data-testid='left-nav']") { click_link "Event Tracker" }
        expect(page).to have_selector("h1.page-title", text: "Event Tracker")
      end
    end

    context "When 'Gary Guest' clicks the 'User Guide' link" do
      it "Navigates to the 'User Guide' stub page" do
        visit events_path
        within("[data-testid='left-nav']") { click_link "User Guide" }
        expect(page).to have_selector("h1.page-title", text: "User Guide")
      end
    end

    context "When 'Gary Guest' clicks 'Events by day'" do
      it "Navigates to the 'Events by day' page" do
        visit events_path
        within("[data-testid='left-nav']") { click_link "Events by day" }
        expect(page).to have_selector("[data-testid='by-day-heading']")
      end
    end
  end

  # ── Edge Cases ─────────────────────────────────────────────────────────────

  describe "Edge Cases" do
    context "When 'Adam Administrator' is signed in" do
      let(:adam) { create(:user, :admin) }

      before do
        sign_in_as(adam)
        visit events_path
      end

      it "Shows the 'Actions' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-actions-h2']")
          expect(page).to have_link("Create Event Type", href: new_event_type_path)
        end
      end

      it "Shows the 'Import & Export' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-import-export-h2']")
        end
      end
    end

    context "When 'Sam System Admin' is signed in" do
      let(:sam) { create(:user, :system_admin) }

      before do
        sign_in_as(sam)
        visit events_path
      end

      it "Shows the 'Actions' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-actions-h2']")
        end
      end

      it "Shows the 'Import & Export' section" do
        within("[data-testid='left-nav']") do
          expect(page).to have_selector("[data-testid='left-nav-import-export-h2']")
        end
      end
    end
  end
end
