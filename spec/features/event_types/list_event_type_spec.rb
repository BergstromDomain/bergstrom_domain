# spec/features/event_types/list_event_types_spec.rb

require "rails_helper"

RSpec.describe "List event types", type: :feature do
  let!(:work)     { create(:event_type, name: "Work",     icon: "briefcase", description: "Work events.") }
  let!(:birthday) { create(:event_type, name: "Birthday", icon: "cake",      description: "Birthday events.") }
  let!(:sport)    { create(:event_type, name: "Sport",    icon: "trophy",    description: "Sport events.") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { visit event_types_path }

    it "Displays the page title" do
      expect(page).to have_selector("h1.page-title", text: "Event Types")
    end

    it "Displays all event types" do
      expect(page).to have_content("Work")
      expect(page).to have_content("Birthday")
      expect(page).to have_content("Sport")
    end

    it "Displays event types in alphabetical order by name" do
      expect(page.text.index("Birthday")).to be < page.text.index("Sport")
      expect(page.text.index("Sport")).to be < page.text.index("Work")
    end

    it "Renders an SVG icon for each event type" do
      expect(page).to have_selector("td[data-testid='event-type-icon'] svg", minimum: 3)
    end

    it "Displays the description for each event type" do
      expect(page).to have_selector("td[data-testid='event-type-description']", count: 3)
    end

    it "Links each event type name to its show page" do
      expect(page).to have_link("Work",     href: event_type_path(work))
      expect(page).to have_link("Birthday", href: event_type_path(birthday))
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Displays an empty state message when no event types exist" do
      EventType.delete_all
      visit event_types_path
      expect(page).to have_http_status(:ok)
      expect(page).to have_selector("[data-testid='empty-state']")
      expect(page).not_to have_selector(".data-table")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Renders the same page regardless of authentication status" do
      sign_in_as create(:user, :app_user)
      visit event_types_path
      expect(page).to have_selector("h1.page-title", text: "Event Types")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Sorts event types case-insensitively" do
      create(:event_type, name: "acoustic sessions", icon: "headphones", description: "Informal sessions.")
      visit event_types_path
      expect(page.text.index("acoustic sessions")).to be < page.text.index("Birthday")
    end
  end
end
