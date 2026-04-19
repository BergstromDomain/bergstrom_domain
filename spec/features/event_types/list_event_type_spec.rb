# spec/features/event_types/list_event_type_spec.rb
require "rails_helper"

RSpec.describe "List event types", type: :feature do
  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    it "displays all event types" do
      create(:event_type, name: "Work",     icon: "briefcase", description: "Work events.")
      create(:event_type, name: "Birthday", icon: "cake",      description: "Birthday events.")
      visit event_types_path

      expect(page).to have_content("Work")
      expect(page).to have_content("Birthday")
    end

    it "renders an SVG icon for each event type" do
      create(:event_type, name: "Work",     icon: "briefcase", description: "Work events.")
      create(:event_type, name: "Birthday", icon: "cake",      description: "Birthday events.")
      visit event_types_path

      expect(page).to have_css("svg", minimum: 2)
    end

    it "displays event types in alphabetical order by name" do
      create(:event_type, name: "Work",     icon: "briefcase", description: "Work events.")
      create(:event_type, name: "Birthday", icon: "cake",      description: "Birthday events.")
      create(:event_type, name: "Sport",    icon: "trophy",    description: "Sport events.")
      visit event_types_path

      expect(page.text.index("Birthday")).to be < page.text.index("Sport")
      expect(page.text.index("Sport")).to be < page.text.index("Work")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "displays an empty page when no event types exist" do
      visit event_types_path

      expect(page).to have_http_status(:ok)
      expect(page).not_to have_css(".event-type")
    end
  end
end
