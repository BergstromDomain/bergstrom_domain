# spec/features/contacts/contacts_management_spec.rb
require "rails_helper"

RSpec.describe "Contacts Management", type: :feature do
  let!(:uno)     { create(:user, first_name: "Uno",     last_name: "User") }
  let!(:ulrika)  { create(:user, first_name: "Ulrika",  last_name: "User") }
  let!(:charlie) { create(:user, :content_creator, first_name: "Charlie", last_name: "Creator") }
  let!(:curtis)  { create(:user, :content_creator, first_name: "Curtis",  last_name: "Creator") }

  describe "Happy Path" do
    it "Uno sends a request, Ulrika sees it as incoming and accepts it" do
      contact = create(:contact, user: uno, contact: ulrika, status: "pending")

      sign_in_as ulrika
      visit contacts_path
      within("[data-testid='incoming-pending-contacts']") do
        expect(page).to have_content("Uno User")
        find("[data-testid='accept-contact-#{contact.id}']").click
      end

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='my-contacts-panel']") do
        expect(page).to have_content("Uno User")
      end
      expect(Contact.confirmed_between?(uno, ulrika)).to be true
    end

    it "Charlie sends a request and Curtis declines it, removing the row entirely" do
      contact = create(:contact, user: charlie, contact: curtis, status: "pending")

      sign_in_as curtis
      visit contacts_path
      expect {
        find("[data-testid='reject-contact-#{contact.id}']").click
      }.to change(Contact, :count).by(-1)

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='incoming-pending-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-incoming']")
      end
    end

    it "Removes a confirmed contact" do
      contact = create(:contact, user: uno, contact: ulrika, status: "confirmed")

      sign_in_as uno
      visit contacts_path
      within("[data-testid='my-contacts-panel']") do
        expect(page).to have_content("Ulrika User")
        find("[data-testid='remove-contact-#{contact.id}']").click
      end

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='my-contacts-panel']") do
        expect(page).to have_css("[data-testid='empty-state-confirmed']")
      end
      expect(Contact.confirmed_between?(uno, ulrika)).to be false
    end

    # TODO: JS session isolation issue — sign_in_as does not authenticate
    # under the js:true/Selenium driver anywhere in this app (see the same
    # TODO in create_event_spec.rb/create_person_spec.rb/edit_person_spec.rb).
    # Server-side search behavior is covered by spec/requests/contacts_spec.rb.
    xit "searches for a user by name and sends them a request", js: true do
      sign_in_as uno
      visit contacts_path

      fill_in "Search by name", with: "Ulrika"
      within("[data-testid='contact-search-results']") do
        expect(page).to have_content("Ulrika User")
        find("[data-testid='connect-contact-#{ulrika.id}']").click
      end

      expect(page).to have_css("[data-testid='flash-notice']")
      within("[data-testid='outgoing-pending-contacts']") do
        expect(page).to have_content("Ulrika User")
      end
    end
  end

  describe "Negative Path" do
    # TODO: JS session isolation issue — see TODO above.
    xit "shows no results when searching for a name that doesn't match anyone", js: true do
      sign_in_as uno
      visit contacts_path
      fill_in "Search by name", with: "Nobody"

      within("[data-testid='contact-search-results']") do
        expect(page).to have_css("[data-testid='empty-state-search']")
      end
    end
  end

  describe "Alternative Path" do
    it "Allows the requester to cancel their own outgoing request" do
      contact = create(:contact, user: uno, contact: ulrika, status: "pending")

      sign_in_as uno
      visit contacts_path
      expect {
        find("[data-testid='cancel-contact-#{contact.id}']").click
      }.to change(Contact, :count).by(-1)

      within("[data-testid='outgoing-pending-contacts']") do
        expect(page).to have_css("[data-testid='empty-state-outgoing']")
      end
    end
  end
end
