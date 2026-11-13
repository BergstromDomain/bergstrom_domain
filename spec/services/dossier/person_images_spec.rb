# spec/services/dossier/person_images_spec.rb

require "rails_helper"

RSpec.describe Dossier::PersonImages do
  let(:charlie) { create(:user, :content_creator) }
  let(:dir) { Pathname(Dir.mktmpdir) }
  let!(:andrew) { create(:person, user: charlie, first_name: "Andrew", last_name: "Job") }

  after { FileUtils.rm_rf(dir) }

  def photo(name) = FileUtils.cp(file_fixture(name.end_with?(".png") ? "test_image.png" : "test_image.jpg"), dir.join(name))
  def run(dry_run: false) = described_class.new(charlie, dir).run!(dry_run: dry_run)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Attaches a photo named after the Person" do
      photo("Andrew Job.jpg")

      expect(run).to eq([ "Attached: Andrew Job.jpg → Andrew Job" ])
      expect(andrew.reload.image).to be_attached
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves a Person who already has an image" do
      andrew.image.attach(file_fixture("test_image.png"))
      photo("Andrew Job.jpg")

      expect(run).to eq([ "Skipped, already has an image: Andrew Job.jpg → Andrew Job" ])
      expect(andrew.reload.image.filename.to_s).to eq("test_image.png")
    end

    it "Reports a file that isn't a JPEG, PNG or WebP, and one matching nobody" do
      dir.join("Andrew Job.gif").write("GIF89a")
      dir.join("Notes.txt").write("not an image")
      photo("Nobody Here.jpg")

      expect(run).to contain_exactly("Not a JPEG, PNG or WebP: Andrew Job.gif", "Not a JPEG, PNG or WebP: Notes.txt",
                                     "No match: Nobody Here.jpg")
      expect(andrew.reload.image).not_to be_attached
    end

    it "Never matches another user's People" do
      create(:person, first_name: "Frodo", last_name: "Baggins")
      photo("Frodo Baggins.jpg")

      expect(run).to eq([ "No match: Frodo Baggins.jpg" ])
    end

    it "Reports a file whose content isn't an image, whatever its name" do
      dir.join("Andrew Job.jpg").write("not really a JPEG")

      expect(run).to eq([ "Not a JPEG, PNG or WebP: Andrew Job.jpg" ])
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Matches by the LinkedIn username, as LinkedIn's photo URLs and slugs use it" do
      andrew.update!(linkedin_url: "https://www.linkedin.com/in/andrew-job-12345/")
      photo("andrew-job-12345.png")

      expect(run).to eq([ "Attached: andrew-job-12345.png → Andrew Job" ])
    end

    it "Matches a name in any case, with Swedish letters, and its middle name" do
      ake = create(:person, user: charlie, first_name: "Åke", last_name: "Billman")
      alex = create(:person, user: charlie, first_name: "Alexander", middle_name: "En Hao", last_name: "Yue")
      photo("ÅKE BILLMAN.jpeg")
      photo("alexander en hao yue.jpg")
      run

      expect([ ake.reload.image, alex.reload.image ]).to all(be_attached)
    end

    it "Saves nothing on a dry run, reporting what it would do" do
      photo("Andrew Job.jpg")

      expect(run(dry_run: true)).to eq([ "Attached: Andrew Job.jpg → Andrew Job" ])
      expect(andrew.reload.image).not_to be_attached
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    # Full names are unique, but one Person's name can be another's LinkedIn username.
    it "Leaves a file two People match as ambiguous" do
      andrew.update!(linkedin_url: "https://www.linkedin.com/in/ajob")
      other = create(:person, user: charlie, first_name: "Ajob", middle_name: nil, last_name: nil)
      photo("ajob.jpg")

      expect(run).to eq([ "Ambiguous, matches Ajob and Andrew Job: ajob.jpg" ])
      expect([ andrew.reload.image, other.reload.image ]).to all(satisfy { |image| !image.attached? })
    end

    it "Changes nothing when run again" do
      photo("Andrew Job.jpg")
      run
      blob = andrew.reload.image.blob

      expect(run).to eq([ "Skipped, already has an image: Andrew Job.jpg → Andrew Job" ])
      expect(andrew.reload.image.blob).to eq(blob)
    end

    it "Ignores hidden files and folders" do
      dir.join(".DS_Store").write("x")
      dir.join("old").mkdir

      expect(run).to eq([])
    end
  end
end
