# spec/features/shared/failure_artifacts_spec.rb
require "rails_helper"

RSpec.describe "Failure Artifacts", type: :feature do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(directory) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Saves a full-page screenshot, the HTML and the browser log for a browser test", js: true do
      visit contact_path
      page.execute_script("document.body.style.minHeight = '2000px'")

      files = FailureArtifacts.save(page, "Contact page fails", directory: directory)

      expect(files.map { |file| file.basename.to_s })
        .to contain_exactly("contact-page-fails.png", "contact-page-fails.html", "contact-page-fails.log")
      expect(File.binread(files.first, 8, 16).unpack("N2").last).to be >= 2000
      expect(directory.join("contact-page-fails.log").read).to start_with("path: /contact")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Saves nothing when no page was visited" do
      expect(FailureArtifacts.save(page, "Nothing visited", directory: directory)).to be_empty
      expect(directory.children).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Saves only the HTML for a test without a browser" do
      visit contact_path

      files = FailureArtifacts.save(page, "Contact page fails", directory: directory)

      expect(files.map { |file| file.basename.to_s }).to eq([ "contact-page-fails.html" ])
      expect(files.first.read).to include('data-testid="contact-panel"')
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shortens a long example name to 100 characters" do
      visit contact_path

      files = FailureArtifacts.save(page, "word " * 50, directory: directory)

      expect(files.first.basename(".html").to_s.length).to eq(100)
    end
  end
end
