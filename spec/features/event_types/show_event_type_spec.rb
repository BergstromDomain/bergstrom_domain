# spec/features/event_types/show_event_type_spec.rb

require "rails_helper"

RSpec.describe "Show event type", type: :feature do
  let(:admin)           { create(:user, :admin) }
  let(:content_creator) { create(:user, :content_creator) }
  let!(:event_type) do
    create(:event_type,
      name:        "Music",
      icon:        "music",
      description: "Musical events and performances.")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "happy path" do
    before { visit event_type_path(event_type) }

    it "displays the event type name in the page title" do
      expect(page).to have_css("h1.page-title", text: "Music")
    end

    it "renders the icon in the page title" do
      expect(page).to have_css(".page-header__icon svg")
    end

    it "displays the event type description" do
      expect(page).to have_css("[data-testid='event-type-description']",
                               text: "Musical events and performances.")
    end

    it "displays the icon name" do
      expect(page).to have_css("[data-testid='event-type-icon-name']", text: "music")
    end

    it "shows a back link to the index" do
      expect(page).to have_link("Back to Event Types", href: event_types_path)
    end

    it "does not show Edit or Delete to an unauthenticated visitor" do
      expect(page).not_to have_link("Edit Music")
      expect(page).not_to have_button("Delete Music")
    end

    it "is accessible by slug" do
      visit event_type_path(event_type.slug)
      expect(page).to have_css("h1.page-title", text: "Music")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "negative path" do
    it "returns 404 for a non-existent slug" do
      visit event_type_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "does not show Edit or Delete to a content creator" do
      sign_in_as content_creator
      visit event_type_path(event_type)
      expect(page).not_to have_link("Edit Music")
      expect(page).not_to have_button("Delete Music")
    end

    it "does not show Edit or Delete to an app user" do
      sign_in_as create(:user, :app_user)
      visit event_type_path(event_type)
      expect(page).not_to have_link("Edit Music")
      expect(page).not_to have_button("Delete Music")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "alternative path" do
    context "as an admin" do
      before do
        sign_in_as admin
        visit event_type_path(event_type)
      end

      it "shows the Edit button" do
        expect(page).to have_link("Edit Music", href: edit_event_type_path(event_type))
      end

      it "shows the Delete button" do
        expect(page).to have_button("Delete Music")
      end

      it "shows the btn-divider between Back and Edit" do
        expect(page).to have_css(".btn-divider")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "edge cases" do
    it "handles an event type with a long name without breaking layout" do
      long = create(:event_type, name: "A" * 60, description: "Test.", icon: "star")
      visit event_type_path(long)
      expect(page).to have_css("h1.page-title")
    end

    it "shows both Edit and Delete to a system admin" do
      sign_in_as create(:user, :system_admin)
      visit event_type_path(event_type)
      expect(page).to have_link("Edit Music")
      expect(page).to have_button("Delete Music")
    end
  end
end
