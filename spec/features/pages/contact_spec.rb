# spec/features/pages/home_spec.rb
require "rails_helper"

RSpec.describe "Contact page", type: :feature do
  describe "Happy path" do
    context "When 'Gary Guest' visits the 'Contact' page" do
      it "Renders the 'Under Construction' paragraph" do
        visit contact_path
        expect(page).to have_content("Under construction")
      end
    end

    context "When 'Uno User' is signed in and visits the 'Contact' page" do
      let(:uno) { create(:user) }

      before do
        sign_in_as(uno)
      end

      it "Renders the 'Under Construction' paragraph" do
        visit contact_path
        expect(page).to have_content("Under construction")
      end
    end
  end
end
