# spec/features/pages/static_pages_spec.rb
require "rails_helper"

RSpec.describe "Static Pages", type: :feature do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    context "When 'Gary Guest' visits the 'Home' page" do
      it "Renders without error" do
        visit root_path
        expect(page).to have_http_status(:ok)
      end
    end

    context "When 'Gary Guest' visits the 'About' page" do
      it "Renders without error" do
        visit about_path
        expect(page).to have_http_status(:ok)
      end
    end

    context "When 'Gary Guest' visits the 'Contact' page" do
      it "Renders without error" do
        visit contact_path
        expect(page).to have_http_status(:ok)
      end
    end
  end
end
