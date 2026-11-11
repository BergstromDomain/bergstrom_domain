# spec/models/person_contact_spec.rb
require "rails_helper"

# A Person's Contact details: Work Email, and LinkedIn (their LinkedIn Social
# Media account, as a profile URL). Dossier's Colleagues and Staff are People.
RSpec.describe Person, type: :model do
  let(:person) { create(:person, first_name: "Anna", last_name: "Andersson") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Has a Work Email" do
      person.update!(work_email: "anna@example.com")

      expect(person.reload.work_email).to eq("anna@example.com")
    end

    it "Keeps a LinkedIn profile URL as its LinkedIn account's username" do
      person.update!(linkedin_url: "https://www.linkedin.com/in/anna-andersson-123/")

      account = person.person_social_media_accounts.sole
      expect(account).to have_attributes(username: "anna-andersson-123")
      expect(account.social_media_platform.name).to eq("LinkedIn")
      expect(person.reload.linkedin_url).to eq("https://www.linkedin.com/in/anna-andersson-123")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects a Work Email that isn't one" do
      person.work_email = "anna-at-example"

      expect(person).not_to be_valid
      expect(person.errors[:work_email]).to include("is invalid")
    end

    it "Can't be deleted while it's a Dossier Colleague or Staff member" do
      create(:dossier_colleague, person: person)

      expect(person.destroy).to be(false)
      expect(person.errors[:base].first).to match(/Anna Andersson is a Colleague or Staff member in Dossier/)
      expect(Person.exists?(person.id)).to be(true)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Uses the existing LinkedIn platform, whatever its case, and updates the account" do
      platform = create(:social_media_platform, name: "linkedin")
      person.update!(linkedin_url: "anna")
      person.update!(linkedin_url: "linkedin.com/in/anna-a")

      expect(person.person_social_media_accounts.sole).to have_attributes(social_media_platform_id: platform.id,
                                                                          username: "anna-a")
    end

    it "Removes the LinkedIn account when it's blanked" do
      person.update!(linkedin_url: "https://www.linkedin.com/in/anna")
      person.reload.update!(linkedin_url: " ")

      expect(person.person_social_media_accounts).to be_empty
      expect(person.linkedin_url).to be_nil
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps a LinkedIn URL that isn't a /in/ profile whole" do
      person.update!(linkedin_url: "https://www.linkedin.com/pub/anna")

      expect(person.reload.linkedin_url).to eq("https://www.linkedin.com/pub/anna")
    end

    it "Strips the Work Email and blanks an empty one" do
      person.update!(work_email: "  anna@example.com ")
      expect(person.work_email).to eq("anna@example.com")
      person.update!(work_email: " ")
      expect(person.work_email).to be_nil
    end

    it "Ignores another platform's account" do
      create(:person_social_media_account, person: person, username: "anna_insta")

      expect(person.reload.linkedin_url).to be_nil
    end
  end
end
