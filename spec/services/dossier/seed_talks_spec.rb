# spec/services/dossier/seed_talks_spec.rb

require "rails_helper"

RSpec.describe Dossier::SeedTalks do
  let(:charlie) { create(:user, :content_creator) }
  let(:soft) { create(:dossier_skill_category, name: "Soft Skills", soft: true) }
  let!(:presenting) { create(:dossier_skill, name: "Communication & Presentation", skill_category: soft) }
  let!(:sharing) { create(:dossier_skill, name: "Knowledge Sharing", skill_category: soft) }
  let!(:robot) { create(:dossier_skill, name: "Robot Framework") }
  let!(:plotlogic) { employed_at("Plotlogic") }
  let!(:elysium) { employed_at("Elysium Digital") }
  let(:poster_dir) { Pathname(Dir.mktmpdir) }

  let(:statistics_title) { described_class::TALKS.first[:title] }
  let(:robot_title) { described_class::TALKS.second[:title] }

  after { FileUtils.rm_rf(poster_dir) }

  def employed_at(name)
    create(:dossier_engagement, user: charlie, employer: create(:dossier_organisation, name: name))
  end

  def posters!
    %w[Statistical.avif Robot.avif].each { |name| FileUtils.cp(file_fixture("albums/load.jpg"), poster_dir.join(name)) }
  end

  def talk(title) = charlie.dossier_contributions.find_by!(title: title)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds both talks at All Things Testing Brisbane, with their dates, venues, Engagements, Skills and posters" do
      posters!
      notes = described_class.new(charlie, poster_dir: poster_dir).run!.notes

      statistics = talk(statistics_title)
      expect(statistics).to have_attributes(kind: "talk", start_on: Date.new(2023, 4, 19), start_precision: "day",
                                            location: "The Annex, Level 6, 12 Creek Street, Brisbane City",
                                            presented_as: "Technical test specialist", engagement: plotlogic)
      expect(statistics.event.name).to eq("All Things Testing Brisbane")
      expect(statistics.skills.map(&:name)).to contain_exactly("Statistics", "Communication & Presentation", "Knowledge Sharing")
      expect(statistics.files.map { |file| file.filename.to_s }).to eq([ "Statistical.avif" ])
      robot_talk = talk(robot_title)
      expect(robot_talk).to have_attributes(start_on: Date.new(2024, 11, 19), engagement: elysium,
                                            presented_as: "Test Manager, Elysium Digital")
      expect(robot_talk.skills).to contain_exactly(robot, presenting, sharing)
      expect(robot_talk.event).to eq(statistics.event)
      expect(notes).to eq([ "Added Organisation All Things Testing Brisbane", "Added: #{statistics_title}", "Added: #{robot_title}" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves out \"During\" when the user has no Engagement with that employer" do
      plotlogic.update_columns(deleted_at: Time.current)
      described_class.new(charlie).run!

      expect(talk(statistics_title).engagement).to be_nil
    end

    it "Adds no posters without a poster folder, or when the poster isn't there" do
      described_class.new(charlie).run!
      described_class.new(charlie, poster_dir: poster_dir).run!

      expect(charlie.dossier_contributions.flat_map(&:files)).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Brings a talk already there in line, by title in any case, keeping its poster and classification" do
      existing = create(:dossier_contribution, user: charlie, title: statistics_title.upcase, location: "Husdon",
                                               engagement: elysium, classification: "unrestricted",
                                               skills_text: "Presentations", soft_skill_ids: [ sharing.id ])
      posters!
      existing.files.attach(io: poster_dir.join("Statistical.avif").open, filename: "Statistical.avif")
      notes = described_class.new(charlie, poster_dir: poster_dir).run!.notes

      expect(existing.reload).to have_attributes(title: statistics_title, location: "The Annex, Level 6, 12 Creek Street, Brisbane City",
                                                 engagement: plotlogic, classification: "unrestricted")
      expect(existing.skills.map(&:name)).to contain_exactly("Statistics", "Communication & Presentation", "Knowledge Sharing")
      expect(existing.files.size).to eq(1)
      expect(notes).to include("Updated: #{statistics_title}")
      expect(charlie.dossier_contributions.count).to eq(2)
    end

    it "Uses an existing All Things Testing Brisbane Organisation, whatever its case" do
      event = create(:dossier_organisation, name: "all things testing brisbane")
      described_class.new(charlie).run!

      expect(talk(robot_title).event).to eq(event)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Changes nothing when run again" do
      posters!
      described_class.new(charlie, poster_dir: poster_dir).run!
      stamps = charlie.dossier_contributions.pluck(:updated_at)

      notes = described_class.new(charlie, poster_dir: poster_dir).run!.notes

      expect(notes).to eq([ "Unchanged: #{statistics_title}", "Unchanged: #{robot_title}" ])
      expect(charlie.dossier_contributions.pluck(:updated_at)).to eq(stamps)
      expect(ActiveStorage::Attachment.where(record_type: "Dossier::Contribution").count).to eq(2)
    end

    it "Adds the talks again when the earlier ones were deleted, leaving those to the purge" do
      described_class.new(charlie).run!
      charlie.dossier_contributions.each(&:soft_delete!)
      described_class.new(charlie).run!

      expect(charlie.dossier_contributions.kept.count).to eq(2)
      expect(charlie.dossier_contributions.discarded.count).to eq(2)
    end

    it "Only touches the given user's talks" do
      other = create(:dossier_contribution, title: statistics_title)
      described_class.new(charlie).run!

      expect(other.reload.location).to be_nil
    end
  end
end
