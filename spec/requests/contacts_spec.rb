# spec/requests/contacts_spec.rb
require "rails_helper"

RSpec.describe "Contacts", type: :request do
  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }

  # 1) Happy path ───────────────────────────────────────────────────────────
  describe "happy path" do
    it "renders the index for an authenticated user" do
      sign_in_as(alice)
      get contacts_path
      expect(response).to have_http_status(:ok)
    end

    it "sends a pending request to a user found by email address" do
      sign_in_as(alice)
      expect {
        post contacts_path, params: { email_address: bob.email_address }
      }.to change { Contact.where(user: alice, contact: bob, status: "pending").count }.by(1)
      expect(response).to redirect_to(contacts_path)
    end

    it "confirms an incoming pending request" do
      contact = create(:contact, user: alice, contact: bob, status: "pending")
      sign_in_as(bob)
      patch confirm_contact_path(contact)
      expect(contact.reload.status).to eq("confirmed")
      expect(response).to redirect_to(contacts_path)
    end

    it "destroys a confirmed contact when removed by the recipient" do
      contact = create(:contact, user: alice, contact: bob, status: "confirmed")
      sign_in_as(bob)
      expect {
        delete remove_contact_path(contact)
      }.to change(Contact, :count).by(-1)
      expect(response).to redirect_to(contacts_path)
    end
  end

  # 2) Negative path ────────────────────────────────────────────────────────
  describe "negative path" do
    it "redirects an unauthenticated request to index" do
      get contacts_path
      expect(response).to redirect_to(new_session_path)
    end

    it "does not create a contact when no user exists with that email address" do
      sign_in_as(alice)
      expect {
        post contacts_path, params: { email_address: "nobody@example.com" }
      }.not_to change(Contact, :count)
      expect(response).to redirect_to(contacts_path)
    end

    it "does not allow the sender to confirm their own outgoing request" do
      contact = create(:contact, user: alice, contact: bob, status: "pending")
      sign_in_as(alice)
      patch confirm_contact_path(contact)
      expect(contact.reload.status).to eq("pending")
    end

    it "does not allow an unrelated user to destroy someone else's contact" do
      contact  = create(:contact, user: alice, contact: bob, status: "confirmed")
      outsider = create(:user)
      sign_in_as(outsider)
      expect {
        delete remove_contact_path(contact)
      }.not_to change(Contact, :count)
    end
  end

  # 3) Alternative path ─────────────────────────────────────────────────────
  describe "alternative path" do
    it "auto-confirms instead of duplicating a row when a reverse pending request already exists" do
      # Bob already has a pending request out to Alice.
      create(:contact, user: bob, contact: alice, status: "pending")
      sign_in_as(alice)

      expect {
        post contacts_path, params: { email_address: bob.email_address }
      }.not_to change(Contact, :count)

      expect(Contact.confirmed_between?(alice, bob)).to be true
      expect(Contact.where(status: "pending").count).to eq(0)
    end

    it "allows the requester to cancel their own outgoing pending request" do
      contact = create(:contact, user: alice, contact: bob, status: "pending")
      sign_in_as(alice)
      expect {
        delete remove_contact_path(contact)
      }.to change(Contact, :count).by(-1)
    end
  end

  # 4) Edge cases ───────────────────────────────────────────────────────────
  describe "edge cases" do
    it "surfaces a validation error rather than crashing when adding yourself" do
      sign_in_as(alice)
      expect {
        post contacts_path, params: { email_address: alice.email_address }
      }.not_to change(Contact, :count)
      expect(response).to redirect_to(contacts_path)
    end
  end
end
