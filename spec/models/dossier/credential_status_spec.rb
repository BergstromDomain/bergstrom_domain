# spec/models/dossier/credential_status_spec.rb
require "rails_helper"

# A Credential's status: To Do, In Progress or Completed. Completed needs a
# Completed date, the others must not have one, and only To Do may leave the
# Started date blank. Left unset, it follows the dates.
RSpec.describe "Dossier Credential status", type: :model do
  let(:user) { create(:user, :content_creator) }

  def credential(**attributes) = build(:dossier_credential, user: user, **attributes)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Has a status column that can't be null" do
      expect(Dossier::Credential.new).to have_db_column(:status).of_type(:string).with_options(null: false)
    end

    it "Is Completed when it has a Completed date and no status was chosen" do
      expect(create(:dossier_credential, user: user)).to be_completed
    end

    it "Is In Progress when it has no Completed date and no status was chosen" do
      expect(create(:dossier_credential, user: user, end_on: nil)).to be_in_progress
    end

    it "Keeps a chosen status" do
      expect(create(:dossier_credential, user: user, end_on: nil, status: "todo")).to be_todo
    end

    it "Lists the statuses in order with their labels" do
      expect(Dossier::Credential::STATUS_LABELS).to eq("todo" => "To Do", "in_progress" => "In Progress",
                                                       "completed" => "Completed")
      expect(credential(status: "in_progress").status_label).to eq("In Progress")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Can't be Completed without a Completed date" do
      record = credential(status: "completed", end_on: nil)

      expect(record).not_to be_valid
      expect(record.errors[:end_month]).to include("is needed when the status is Completed")
    end

    it "Can't be To Do or In Progress with a Completed date" do
      %w[todo in_progress].each do |status|
        record = credential(status: status)

        expect(record).not_to be_valid
        expect(record.errors[:end_month]).to include("must be empty until the status is Completed")
      end
    end

    it "Needs a Started date when In Progress" do
      record = credential(status: "in_progress", start_on: nil, end_on: nil)

      expect(record).not_to be_valid
      expect(record.errors[:start_month]).to include("can't be blank")
    end

    it "Rejects an unknown status" do
      record = credential(status: "abandoned")

      expect(record).not_to be_valid
      expect(record.errors[:status]).to include("is not included in the list")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "May leave the Started date blank when To Do" do
      record = create(:dossier_credential, user: user, status: "todo", start_on: nil, end_on: nil)

      expect(record).to be_valid
      expect(record.dates).to eq("—")
    end

    it "Leaves To Do out of the started scope" do
      todo = create(:dossier_credential, user: user, status: "todo", start_on: nil, end_on: nil)
      done = create(:dossier_credential, user: user)

      expect(Dossier::Credential.started).to eq([ done ])
      expect(Dossier::Credential.started).not_to include(todo)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an In Progress course's dates as started, in progress" do
      expect(credential(status: "in_progress", end_on: nil).dates).to eq("Mar 2020 – in progress")
    end

    it "Leaves a To Do course off the CV and out of Skill experience" do
      course = create(:dossier_credential, user: user, status: "todo", start_on: nil, end_on: nil, skills_text: "Ansible")

      expect(Dossier::CvDocument.new(user).credentials).to be_empty
      expect(Dossier::ExperienceCalculator.new(user).for_skill(Dossier::Skill.find_by!(name: "Ansible"))).to be_nil
      expect(course).to be_persisted
    end
  end
end
