# spec/features/pages/home_spec.rb
require "rails_helper"

RSpec.describe "Home page", type: :feature do
  describe "Happy path" do
    context "When 'Gary Guest' visits the 'Home' page" do
      it "Renders the 'Under Construction' paragraph" do
        visit root_path
        expect(page).to have_content("Under construction")
      end

      it "Renders the 'Sign-Up' button" do
        visit root_path
        expect(page).to have_selector("[data-testid='home-sign-up']")
      end
    end

    context "When 'Uno User' is signed in and visits the 'Home' page" do
      let(:uno) { create(:user) }

      before do
        sign_in_as(uno)
      end

      it "Renders the 'Under Construction' paragraph" do
        visit root_path
        expect(page).to have_content("Under construction")
      end

      it "Renders the 'Sign-Up' button" do
        visit root_path
        expect(page).to have_selector("[data-testid='home-sign-up']")
      end
    end
  end
end
