# spec/models/dossier/profile_spec.rb
require "rails_helper"

RSpec.describe Dossier::Profile, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:display_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:headline).of_type(:string) }
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:phone).of_type(:string) }
    it { is_expected.to have_db_column(:website_url).of_type(:string) }
    it { is_expected.to have_db_column(:linkedin_url).of_type(:string) }
    it { is_expected.to have_db_column(:github_url).of_type(:string) }
    it { is_expected.to have_db_column(:summary).of_type(:text) }
    it { is_expected.to have_db_column(:summary_first_person).of_type(:text) }
    it { is_expected.to have_db_column(:summary_third_person).of_type(:text) }
    it { is_expected.to have_db_column(:third_person_name).of_type(:string) }
    it { is_expected.to have_db_column(:pronouns).of_type(:string).with_options(null: false, default: "they") }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:location).optional }

    it "Is the user's dossier_profile, destroyed with the user" do
      profile = create(:dossier_profile)
      expect(profile.user.dossier_profile).to eq(profile)
      expect { profile.user.destroy }.to change(described_class, :count).by(-1)
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is valid with a display name" do
      expect(build(:dossier_profile)).to be_valid
    end

    it "Is Private by default and uses the display name as its toast label" do
      profile = build(:dossier_profile, display_name: "Alex Example")
      expect(profile.classification).to eq("restricted")
      expect(profile.to_toast_label).to eq("Alex Example")
    end

    it "Starts a new profile from the user's name" do
      user = create(:user, :content_creator, first_name: "Alex", last_name: "Example")
      profile = described_class.for(user)
      expect(profile).to be_new_record
      expect([ profile.display_name, profile.third_person_name ]).to eq([ "Alex Example", "Alex" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a display name" do
      profile = build(:dossier_profile, display_name: " ")
      expect(profile).not_to be_valid
      expect(profile.errors[:display_name]).to include("can't be blank")
    end

    it "Is invalid with a second profile for the same user" do
      profile = create(:dossier_profile)
      duplicate = build(:dossier_profile, user: profile.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end

    it "Is invalid with a link that isn't an http(s) URL" do
      %i[website_url linkedin_url github_url].each do |attribute|
        profile = build(:dossier_profile, attribute => "javascript:alert(1)")
        expect(profile).not_to be_valid, attribute
        expect(profile.errors[attribute]).to include("must start with http:// or https://")
      end
    end

    it "Is invalid with an email address that has no @" do
      profile = build(:dossier_profile, email: "alex.example")
      expect(profile).not_to be_valid
      expect(profile.errors[:email]).to be_present
    end

    it "Is invalid with unknown pronouns" do
      expect { build(:dossier_profile, pronouns: "xe") }.not_to raise_error
      expect(build(:dossier_profile, pronouns: "xe")).not_to be_valid
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Returns the user's existing profile instead of a new one" do
      profile = create(:dossier_profile)
      expect(described_class.for(profile.user)).to eq(profile)
    end

    it "Returns the summary for a voice, falling back to the terse summary" do
      profile = build(:dossier_profile, summary: "Test manager with 25+ years.",
                                        summary_first_person: "I am a test manager with 25+ years.")
      expect(profile.summary_for(:first_person)).to eq("I am a test manager with 25+ years.")
      expect(profile.summary_for(:third_person)).to eq("Test manager with 25+ years.")
      expect(profile.summary_for(:implied)).to eq("Test manager with 25+ years.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Stores blank optional fields as nil" do
      profile = create(:dossier_profile, headline: " ", email: "", phone: " ", website_url: "",
                                         summary_first_person: " ")
      expect([ profile.headline, profile.email, profile.phone, profile.website_url, profile.summary_first_person ])
        .to all(be_nil)
    end

    it "Keeps its own display name after the user renames themselves" do
      profile = create(:dossier_profile, display_name: "Alex Example")
      profile.user.update!(first_name: "Alexandra")
      expect(described_class.for(profile.user).display_name).to eq("Alex Example")
    end
  end
end
