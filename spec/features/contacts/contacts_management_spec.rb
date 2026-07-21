# spec/features/contacts/contacts_management_spec.rb
require "rails_helper"

RSpec.describe "Contacts Management", type: :feature do
  let!(:uno)     { create(:user, first_name: "Uno",     last_name: "User") }
  let!(:ulrika)  { create(:user, first_name: "Ulrika",  last_name: "User") }
  let!(:charlie) { create(:user, :content_creator, first_name: "Charlie", last_name: "Creator") }
  let!(:curtis)  { create(:user, :content_creator, first_name: "Curtis",  last_name: "Creator") }

  describe "Happy Path" do
    it "Uno sends a request, Ulrika sees it as incoming and accepts it" do
      sign_in_as uno
      visit contacts_path
      fill_in "Email address", with: ulrika.email_address
      click_button "Send Request"

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='outgoing-pending-contacts']") do
        expect(page).to have_content("Ulrika User")
      end

      sign_in_as ulrika
      visit contacts_path
      within("[data-testid='incoming-pending-contacts']") do
        expect(page).to have_content("Uno User")
        click_button "Accept"
      end

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='confirmed-contacts']") do
        expect(page).to have_content("Uno User")
      end
      expect(Contact.confirmed_between?(uno, ulrika)).to be true
    end

    it "Charlie sends a request and Curtis rejects it, removing the row entirely" do
      sign_in_as charlie
      visit contacts_path
      fill_in "Email address", with: curtis.email_address
      click_button "Send Request"

      sign_in_as curtis
      visit contacts_path
      expect {
        within("[data-testid='incoming-pending-contacts']") { click_button "Reject" }
      }.to change(Contact, :count).by(-1)

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='incoming-pending-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-incoming']")
      end
    end

    it "Removes a confirmed contact" do
      create(:contact, user: uno, contact: ulrika, status: "confirmed")

      sign_in_as uno
      visit contacts_path
      within("[data-testid='confirmed-contacts']") do
        expect(page).to have_content("Ulrika User")
        click_button "Remove"
      end

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='confirmed-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-confirmed']")
      end
      expect(Contact.confirmed_between?(uno, ulrika)).to be false
    end
  end

  describe "Negative Path" do
    it "Shows an alert when sending a request to an email with no matching user" do
      sign_in_as uno
      visit contacts_path
      fill_in "Email address", with: "nobody@example.com"
      click_button "Send Request"

      expect(page).to have_css("[data-testid='flash-alert']")
      within("[data-testid='outgoing-pending-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-outgoing']")
      end
    end
  end

  describe "Alternative Path" do
    it "Allows the requester to cancel their own outgoing request" do
      sign_in_as uno
      visit contacts_path
      fill_in "Email address", with: ulrika.email_address
      click_button "Send Request"

      expect {
        within("[data-testid='outgoing-pending-contacts']") { click_button "Cancel" }
      }.to change(Contact, :count).by(-1)

      within("[data-testid='outgoing-pending-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-outgoing']")
      end
    end
  end
end
