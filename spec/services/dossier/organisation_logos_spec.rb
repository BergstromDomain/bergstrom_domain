# spec/services/dossier/organisation_logos_spec.rb

require "rails_helper"

RSpec.describe Dossier::OrganisationLogos do
  let(:dir) { Pathname(Dir.mktmpdir) }
  let!(:qpt) { create(:dossier_organisation, name: "Queensland Public Trustee", abbreviation: "QPT") }

  after { FileUtils.rm_rf(dir) }

  def logo(name) = FileUtils.cp(file_fixture(name.end_with?(".png") ? "test_image.png" : "test_image.jpg"), dir.join(name))
  def run(dry_run: false) = described_class.new(dir).run!(dry_run: dry_run)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Attaches a logo named after the Organisation, or its abbreviation" do
      apa = create(:dossier_organisation, name: "APA Group")
      logo("APA Group.png")
      logo("QPT.jpg")

      expect(run).to eq([ "Attached: APA Group.png → APA Group", "Attached: QPT.jpg → Queensland Public Trustee" ])
      expect([ apa.reload.logo, qpt.reload.logo ]).to all(be_attached)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves an Organisation that already has a logo" do
      qpt.logo.attach(file_fixture("test_image.png"))
      logo("QPT.jpg")

      expect(run).to eq([ "Skipped, already has a logo: QPT.jpg → Queensland Public Trustee" ])
      expect(qpt.reload.logo.filename.to_s).to eq("test_image.png")
    end

    it "Reports a file matching nobody, and one that isn't a JPEG, PNG or WebP" do
      logo("Nobody.jpg")
      dir.join("QPT.svg").write("<svg xmlns='http://www.w3.org/2000/svg'/>")

      expect(run).to eq([ "No match: Nobody.jpg", "Not a JPEG, PNG or WebP: QPT.svg" ])
      expect(qpt.reload.logo).not_to be_attached
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Saves nothing on a dry run, reporting what it would do" do
      logo("QPT.jpg")

      expect(run(dry_run: true)).to eq([ "Attached: QPT.jpg → Queensland Public Trustee" ])
      expect(qpt.reload.logo).not_to be_attached
    end

    it "Matches in any case, with Swedish letters" do
      kth = create(:dossier_organisation, name: "Kungliga Tekniska Högskolan")
      logo("KUNGLIGA TEKNISKA HÖGSKOLAN.png")
      run

      expect(kth.reload.logo).to be_attached
    end

    it "Ignores a trailing \"logo\", underscores, hyphens and spacing in the file name" do
      pinnacle = create(:dossier_organisation, name: "PinnacleQM")
      elysium  = create(:dossier_organisation, name: "Elysium Digital")
      logo("Pinnacle_QM_logo.jpeg")
      logo("Elysium_Digital-Logo.png")
      logo("QPT logo.jpg")

      expect(run).to eq([ "Attached: Elysium_Digital-Logo.png → Elysium Digital",
                          "Attached: Pinnacle_QM_logo.jpeg → PinnacleQM",
                          "Attached: QPT logo.jpg → Queensland Public Trustee" ])
      expect([ pinnacle.reload.logo, elysium.reload.logo, qpt.reload.logo ]).to all(be_attached)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves a file two Organisations match as ambiguous" do
      create(:dossier_organisation, name: "QPT")
      logo("qpt.jpg")

      expect(run).to eq([ "Ambiguous, matches QPT and Queensland Public Trustee: qpt.jpg" ])
    end

    it "Ignores hidden files and folders" do
      dir.join(".DS_Store").write("x")
      dir.join("old").mkdir

      expect(run).to eq([])
    end
  end
end
