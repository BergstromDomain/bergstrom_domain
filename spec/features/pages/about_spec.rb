# spec/features/pages/home_spec.rb
require "rails_helper"

RSpec.describe "About page", type: :feature do
  describe "Happy path" do
    context "When 'Gary Guest' visits the 'About' page" do
      it "Renders the 'Under Construction' paragraph" do
        visit about_path
        expect(page).to have_content("Under construction")
      end
    end

    context "When 'Uno User' is signed in and visits the 'About' page" do
      let(:uno) { create(:user) }

      before do
        sign_in_as(uno)
      end

      it "Renders the 'Under Construction' paragraph" do
        visit about_path
        expect(page).to have_content("Under construction")
      end
    end
  end
end
