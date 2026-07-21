# spec/features/people/mute_person_spec.rb
require "rails_helper"

RSpec.describe "Mute Person", type: :feature do
  let!(:uno)  { create(:user, first_name: "Uno", last_name: "User") }
  let!(:adam) { create(:person, user: uno, first_name: "Adam", middle_name: nil, last_name: "Ant") }

  describe "happy path" do
    it "mutes a person from the index row" do
      sign_in_as uno
      visit people_path

      expect {
        find("[data-testid='mute-person-#{adam.id}']").click
      }.to change { PersonMute.where(user: uno, person: adam).count }.by(1)

      expect(page).to have_css("[data-testid='flash-notice']")
      expect(page).to have_selector("[data-testid='unmute-person-#{adam.id}']")
    end

    it "unmutes a person from the index row" do
      create(:person_mute, user: uno, person: adam)
      sign_in_as uno
      visit people_path

      expect {
        find("[data-testid='unmute-person-#{adam.id}']").click
      }.to change { PersonMute.where(user: uno, person: adam).count }.by(-1)

      expect(page).to have_selector("[data-testid='mute-person-#{adam.id}']")
    end
  end

  describe "negative path" do
    it "does not show a mute button for unauthenticated visitors" do
      visit people_path
      expect(page).not_to have_selector("[data-testid='person-mute-cell']")
    end
  end
end
