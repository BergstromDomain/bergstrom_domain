# spec/features/event_types/show_event_type_spec.rb
require "rails_helper"

RSpec.describe "Show event type", type: :feature do
  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    let!(:event_type) { create(:event_type, name: "Music", icon: "music", description: "Musical events and performances.") }

    it "displays the event type name" do
      visit event_type_path(event_type)

      expect(page).to have_content("Music")
    end

    it "displays the event type description" do
      visit event_type_path(event_type)

      expect(page).to have_content("Musical events and performances.")
    end

    it "renders the icon as an SVG element" do
      visit event_type_path(event_type)

      expect(page).to have_css("svg")
    end

    it "displays the icon name" do
      visit event_type_path(event_type)

      expect(page).to have_content("music")
    end

    it "is accessible by slug" do
      visit event_type_path(event_type.slug)

      expect(page).to have_content("Music")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "returns 404 for a non-existent slug" do
      visit event_type_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end
  end
end
