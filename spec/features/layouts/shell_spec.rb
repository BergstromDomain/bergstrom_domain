# spec/features/layouts/shell_spec.rb
require "rails_helper"

RSpec.describe "Shell", type: :feature do
  let(:charlie) { create(:user, role: :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    context "When 'Gary Guest' views the shell" do
      it "Renders the top navigation bar" do
        visit root_path
        expect(page).to have_selector("[data-testid='top-nav']")
      end

      it "Renders the footer" do
        visit root_path
        expect(page).to have_selector("[data-testid='footer']")
      end
    end

    context "When 'Charlie Content Creator' views the shell" do
      before { sign_in_as(charlie) }

      it "Renders the top navigation bar" do
        visit root_path
        expect(page).to have_selector("[data-testid='top-nav']")
      end

      it "Renders the footer" do
        visit root_path
        expect(page).to have_selector("[data-testid='footer']")
      end
    end
  end
end
