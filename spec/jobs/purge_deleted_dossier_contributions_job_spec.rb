# spec/jobs/purge_deleted_dossier_contributions_job_spec.rb
require "rails_helper"

RSpec.describe PurgeDeletedDossierContributionsJob, type: :job do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Permanently destroys a Contribution deleted more than 30 days ago, with its Skill tags and files" do
      talk = create(:dossier_contribution, skills_text: "Robot Framework")
      talk.files.attach(io: StringIO.new("poster"), filename: "poster.png", content_type: "image/png")
      talk.update_columns(deleted_at: 31.days.ago)

      expect { described_class.perform_now }.to change(Dossier::ContributionSkill, :count).by(-1)
                                            .and change(ActiveStorage::Attachment, :count).by(-1)
      expect(Dossier::Contribution.exists?(talk.id)).to be(false)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves one deleted less than 30 days ago" do
      talk = create(:dossier_contribution)
      talk.update_columns(deleted_at: 29.days.ago)
      described_class.perform_now

      expect(Dossier::Contribution.exists?(talk.id)).to be(true)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Leaves a kept one, however old" do
      talk = create(:dossier_contribution, created_at: 2.years.ago)
      described_class.perform_now

      expect(Dossier::Contribution.exists?(talk.id)).to be(true)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is scheduled daily" do
      expect(YAML.load_file(Rails.root.join("config/recurring.yml")).values.flat_map(&:values).map { |job| job["class"] })
        .to include("PurgeDeletedDossierContributionsJob")
    end
  end
end
