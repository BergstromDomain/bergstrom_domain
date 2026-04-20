# spec/features/layouts/left_nav_spec.rb
require "rails_helper"

RSpec.describe "Left navigation bar", type: :feature do
  let(:user)            { create(:user) }
  let(:content_creator) { create(:user, role: :content_creator) }

  # ── Static pages — left nav must never appear ──────────────────────────────

  describe "static pages" do
    before { sign_in_as(user) }

    it "is not present on the home page" do
      visit root_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end

    it "is not present on the about page" do
      visit about_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end

    it "is not present on the contact page" do
      visit contact_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end

    it "is not present on the blog posts page" do
      visit blog_posts_path
      expect(page).not_to have_css("[data-testid='left-nav']")
    end
  end

  # ── Unauthenticated visitor ────────────────────────────────────────────────

  describe "unauthenticated visitor on events index" do
    before { visit events_path }

    it "shows the left nav" do
      expect(page).to have_css("[data-testid='left-nav']")
    end

    it "shows the Views section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "Views")
      end
    end

    it "shows the All Events link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("All Events", href: events_path)
      end
    end

    it "shows the People link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("People", href: people_path)
      end
    end

    it "shows the Event Types link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Event Types", href: event_types_path)
      end
    end

    it "shows the How To section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "How To")
      end
    end

    it "does not show the Actions section" do
      within("[data-testid='left-nav']") do
        expect(page).not_to have_css("[data-testid='left-nav-h1']", text: "Actions")
      end
    end

    it "does not show the Import & Export section" do
      within("[data-testid='left-nav']") do
        expect(page).not_to have_css("[data-testid='left-nav-h1']", text: "Import & Export")
      end
    end
  end

  # ── Authenticated user (App User) ─────────────────────────────────────────

  describe "authenticated app user on events index" do
    before do
      sign_in_as(user)
      visit events_path
    end

    it "shows the left nav" do
      expect(page).to have_css("[data-testid='left-nav']")
    end

    it "shows the Views section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "Views")
      end
    end

    it "does not show the Actions section" do
      within("[data-testid='left-nav']") do
        expect(page).not_to have_css("[data-testid='left-nav-h1']", text: "Actions")
      end
    end

    it "does not show the Import & Export section" do
      within("[data-testid='left-nav']") do
        expect(page).not_to have_css("[data-testid='left-nav-h1']", text: "Import & Export")
      end
    end
  end

  # ── Content Creator ────────────────────────────────────────────────────────

  describe "content creator on events index" do
    before do
      sign_in_as(content_creator)
      visit events_path
    end

    it "shows the Actions section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "Actions")
      end
    end

    it "shows the Create Event link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Create Event", href: new_event_path)
      end
    end

    it "shows the Create Event Type link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Create Event Type", href: new_event_type_path)
      end
    end

    it "shows the Create Person link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Create Person", href: new_person_path)
      end
    end

    it "shows the Import & Export section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "Import & Export")
      end
    end
  end

  # ── Event types index ──────────────────────────────────────────────────────

  describe "event types index" do
    before do
      sign_in_as(user)
      visit event_types_path
    end

    it "shows the left nav" do
      expect(page).to have_css("[data-testid='left-nav']")
    end

    it "shows the Views section" do
      within("[data-testid='left-nav']") do
        expect(page).to have_css("[data-testid='left-nav-h1']", text: "Views")
      end
    end
  end
end
