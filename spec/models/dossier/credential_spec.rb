# spec/models/dossier/credential_spec.rb
require "rails_helper"

RSpec.describe Dossier::Credential, type: :model do
  let(:user)       { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: user) }

  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:credential_type_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:expires_on).of_type(:date) }
    it { is_expected.to have_db_column(:expires_precision).of_type(:string).with_options(null: false, default: "month") }
    it { is_expected.to have_db_column(:certificate_number).of_type(:string) }
    it { is_expected.to have_db_column(:verification_url).of_type(:string) }
    it { is_expected.to have_db_column(:hours).of_type(:decimal) }
    it { is_expected.to have_db_column(:classification).of_type(:string).with_options(null: false, default: "restricted") }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:credential_type) }
    it { is_expected.to belong_to(:provider).class_name("Dossier::Organisation").optional }
    it { is_expected.to belong_to(:engagement).optional }
    it { is_expected.to belong_to(:assignment).optional }
    it { is_expected.to have_many(:credential_skills).dependent(:destroy) }
    it { is_expected.to have_many_attached(:files) }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Is a Private course, tagged with Skills typed as text" do
      create(:dossier_skill, name: "Jira")
      course = create(:dossier_credential, user: user, skills_text: "jira, Excel VBA")

      expect(course).to have_attributes(classification: "restricted")
      expect(course).to be_training
      expect(course.reload.skills_text).to eq("Jira, Excel VBA")
      expect(Dossier::Skill.find_by!(name: "Excel VBA").skill_category.name).to eq(Dossier::TechStack::UNCATEGORISED)
    end

    it "Takes its Engagement from its Assignment" do
      assignment = create(:dossier_assignment, engagement: engagement)
      course = create(:dossier_credential, user: user, assignment: assignment)
      expect(course.engagement).to eq(engagement)
    end

    it "Keeps an expiry date, a certificate number and a verification URL" do
      cert = create(:dossier_credential, :certification, user: user, expires_year: "2027", expires_month_number: "3",
                                         expires_day: "31", certificate_number: " SSTBFCE-176004 ",
                                         verification_url: "https://example.com/verify/176004")

      expect(cert.reload).to have_attributes(expires_on: Date.new(2027, 3, 31), expires_precision: "day",
                                             certificate_number: "SSTBFCE-176004", formatted_expiry: "31 Mar 2027")
      expect(cert).not_to be_training
    end

    it "Knows when it has expired, or expires within 90 days" do
      today = Date.new(2026, 11, 5)
      expired = build(:dossier_credential, expires_month: "2026-11", expires_day: "4")
      soon    = build(:dossier_credential, expires_month: "2027-02", expires_day: "3")
      later   = build(:dossier_credential, expires_month: "2027-02", expires_day: "4")

      expect(expired.expired?(today)).to be(true)
      expect(soon).to have_attributes(expired?: false)
      expect(soon.expiring_soon?(today)).to be(true)
      expect(soon.days_until_expiry(today)).to eq(90)
      expect(later.expiring_soon?(today)).to be(false)
    end

    it "Keeps several certificate files: PDFs and images" do
      credential = create(:dossier_credential, files: [
        fixture_file_upload("test_certificate.pdf", "application/pdf"),
        fixture_file_upload("test_image.png", "image/png"),
        fixture_file_upload("test_image.jpg", "image/jpeg")
      ])
      expect(credential.reload.files.map(&:filename).map(&:to_s))
        .to contain_exactly("test_certificate.pdf", "test_image.png", "test_image.jpg")
    end

    it "Lists only training types under training" do
      course = create(:dossier_credential, user: user)
      create(:dossier_credential, :certification, user: user)
      expect(described_class.training).to eq([ course ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Is invalid without a title or a start" do
      course = build(:dossier_credential, title: " ", start_on: nil)
      expect(course).not_to be_valid
      expect(course.errors.attribute_names).to include(:title, :start_month)
    end

    it "Is invalid under another user's Engagement" do
      course = build(:dossier_credential, user: user, engagement: create(:dossier_engagement))
      expect(course).not_to be_valid
      expect(course.errors[:engagement]).to include("must be one of your Engagements")
    end

    it "Is invalid with zero hours" do
      expect(build(:dossier_credential, hours: 0)).not_to be_valid
    end

    it "Is invalid without a type" do
      credential = build(:dossier_credential, credential_type: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:credential_type]).to be_present
    end

    it "Is invalid with a verification URL that isn't http(s)" do
      credential = build(:dossier_credential, verification_url: "example.com/verify")
      expect(credential).not_to be_valid
      expect(credential.errors[:verification_url]).to include("must start with http:// or https://")
    end

    it "Rejects a certificate file that isn't a PDF, JPEG or PNG" do
      credential = build(:dossier_credential, files: [ fixture_file_upload("test_image.gif", "image/gif") ])
      expect(credential).not_to be_valid
      expect(credential.errors[:files]).to include("must be a PDF, JPEG or PNG")
    end

    it "Rejects a certificate file of 10 MB or more" do
      big = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("%PDF-1.4\n" + ("0" * 10.megabytes)),
                                                   filename: "big.pdf", content_type: "application/pdf")
      credential = build(:dossier_credential, files: [ big.signed_id ])
      expect(credential).not_to be_valid
      expect(credential.errors[:files]).to include("must be smaller than 10 MB each")
    end

    it "Is invalid when it expires before it starts" do
      credential = build(:dossier_credential, start_month: "2020-03", expires_month: "2019-12")
      expect(credential).not_to be_valid
      expect(credential.errors[:expires_month]).to include("must not be before the start")
    end

    it "Is invalid with an expiry day that isn't in the month" do
      credential = build(:dossier_credential, expires_month: "2027-02", expires_day: "30")
      expect(credential).not_to be_valid
      expect(credential.errors[:expires_day]).to be_present
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Can stand alone, e.g. a course on the bench" do
      expect(create(:dossier_credential, user: user).engagement).to be_nil
    end

    it "Shows an unfinished course as in progress" do
      course = build(:dossier_credential, start_month: "2024-03", end_month: "")
      expect(course.dates).to eq("Mar 2024 – in progress")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is hidden while its Engagement is deleted, and purged with it" do
      course = create(:dossier_credential, user: user, engagement: engagement)
      engagement.soft_delete!

      expect(course.reload).to be_hidden
      expect(described_class.kept).to be_empty
      engagement.destroy
      expect(described_class.exists?(course.id)).to be(false)
    end

    it "Stays with its Engagement when its Assignment is deleted" do
      assignment = create(:dossier_assignment, engagement: engagement)
      course = create(:dossier_credential, user: user, assignment: assignment)
      assignment.destroy

      expect(course.reload).to have_attributes(assignment_id: nil, engagement_id: engagement.id)
    end

    it "Has no expiry unless one is given, and clears it when emptied" do
      credential = create(:dossier_credential, expires_month: "2027-03")
      expect(credential.formatted_expiry).to eq("Mar 2027")
      credential.update!(expires_year: "", expires_month_number: "")
      expect(credential.reload).to have_attributes(expires_on: nil, formatted_expiry: nil)
    end

    it "Finds Credentials completed during a period, counting a month-precision completion as the whole month" do
      in_month = create(:dossier_credential, start_month: "2020-01", end_month: "2020-02")
      on_day   = create(:dossier_credential, start_month: "2020-01", end_month: "2020-03", end_day: "10")
      create(:dossier_credential, start_month: "2020-01", end_month: "2020-03", end_day: "20")
      create(:dossier_credential, start_month: "2020-01", end_month: "")

      expect(described_class.completed_during(Date.new(2020, 2, 15), Date.new(2020, 3, 15)))
        .to contain_exactly(in_month, on_day)
    end

    it "Counts a month-precision expiry as the whole month" do
      credential = build(:dossier_credential, expires_month: "2026-11")
      expect(credential.expired?(Date.new(2026, 11, 30))).to be(false)
      expect(credential.expired?(Date.new(2026, 12, 1))).to be(true)
    end

    it "Says when it expires today or tomorrow" do
      credential = build(:dossier_credential, expires_month: "2026-11", expires_day: "5")
      expect(credential.expiry_warning(Date.new(2026, 11, 5))).to eq("This Credential expires today, 5 Nov 2026.")
      expect(credential.expiry_warning(Date.new(2026, 11, 4))).to eq("This Credential expires on 5 Nov 2026, in 1 day.")
    end

    it "Never expires without an expiry date" do
      credential = build(:dossier_credential)
      expect(credential.expired?).to be(false)
      expect(credential.expiring_soon?).to be(false)
    end

    it "Takes a year on its own, as year precision" do
      degree = create(:dossier_credential, start_year: "1995", start_month_number: "", end_year: "2001", end_month_number: "")

      expect(degree.reload).to have_attributes(start_on: Date.new(1995, 1, 1), start_precision: "year",
                                               end_on: Date.new(2001, 1, 1), end_precision: "year",
                                               dates: "1995 – 2001", effective_end: Date.new(2001, 12, 31))
      fresh = described_class.find(degree.id)
      expect([ fresh.start_year, fresh.start_month_number, fresh.end_month ]).to eq([ "1995", nil, "2001" ])
    end

    it "Shows a year-only course once and counts it as completed any time that year" do
      course = create(:dossier_credential, start_month: "2012", end_month: "2012")
      expect(course.dates).to eq("2012")
      expect(described_class.completed_during(Date.new(2012, 6, 1), Date.new(2012, 8, 31))).to eq([ course ])
    end

    it "Ignores a day given with only a year" do
      course = build(:dossier_credential, start_month: "2012", start_day: "5", end_month: "2012")
      expect(course).to be_valid
      expect(course.start_precision).to eq("year")
    end

    it "Shows a course within one month once" do
      expect(build(:dossier_credential, start_month: "2020-03", end_month: "2020-03").dates).to eq("Mar 2020")
    end
  end
end
