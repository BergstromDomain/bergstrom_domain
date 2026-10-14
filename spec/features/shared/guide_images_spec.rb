# spec/features/shared/guide_images_spec.rb
require "rails_helper"

RSpec.describe "Guide Images", type: :feature, js: true do
  let(:root) { Pathname.new(Dir.mktmpdir) }

  before do
    root.join("cookbook").mkpath
    GuideImages.root = root
  end

  after do
    GuideImages.root = nil
    FileUtils.remove_entry(root)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Saves the element as a PNG in the app's User Guide images folder" do
      visit contact_path

      path = capture_guide_image("contact-panel", as: "cookbook/contact_panel")

      expect(path).to eq(root.join("cookbook/images/contact_panel.png"))
      expect(File.binread(path, 8)).to eq("\x89PNG\r\n\x1A\n".b)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Rejects a name without an app folder" do
      visit contact_path

      expect { capture_guide_image("contact-panel", as: "contact_panel") }
        .to raise_error(ArgumentError, /app folder/)
    end

    it "Rejects an app without a User Guide folder" do
      visit contact_path

      expect { capture_guide_image("contact-panel", as: "gallery/contact_panel") }
        .to raise_error(ArgumentError, /gallery/)
      expect(root.join("gallery")).not_to exist
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Stops transitions and animations and drops focus before capturing" do
      visit contact_path
      page.execute_script("document.querySelector('[data-testid=\"contact-panel\"]').style.transition = 'opacity 2s'")
      page.execute_script("document.querySelector('a').focus()")

      capture_guide_image("contact-panel", as: "cookbook/contact_panel")

      expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-testid=\"contact-panel\"]')).transitionDuration"))
        .to eq("0s")
      expect(page.evaluate_script("document.activeElement === document.body")).to be(true)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    # Chrome's anti-aliasing can differ by a shade between runs; rewriting the
    # file for that would show an unchanged screen as a changed image in git.
    it "Keeps the existing image when the new capture only differs by a shade" do
      require "vips"
      visit contact_path
      path = capture_guide_image("contact-panel", as: "cookbook/contact_panel")
      shaded = Vips::Image.new_from_file(path.to_s).draw_rect([ 1, 1, 1 ], 0, 0, 2, 2)
      shaded.write_to_file(path.to_s)
      kept = Digest::SHA256.file(path).hexdigest

      capture_guide_image("contact-panel", as: "cookbook/contact_panel")

      expect(Digest::SHA256.file(path).hexdigest).to eq(kept)
    end

    it "Replaces the existing image when something visible changed" do
      visit contact_path
      path = capture_guide_image("contact-panel", as: "cookbook/contact_panel")
      before = Digest::SHA256.file(path).hexdigest
      page.execute_script("document.querySelector('[data-testid=\"contact-intro\"]').textContent = 'Changed text'")

      capture_guide_image("contact-panel", as: "cookbook/contact_panel")

      expect(Digest::SHA256.file(path).hexdigest).not_to eq(before)
    end

    it "Doesn't double the .png extension" do
      visit contact_path

      path = capture_guide_image("contact-panel", as: "cookbook/contact_panel.png")

      expect(path.basename.to_s).to eq("contact_panel.png")
    end

    it "Skips guide_image specs unless GUIDE_SCREENSHOTS is set" do
      expected = ENV["GUIDE_SCREENSHOTS"].present? ? nil : true

      expect(RSpec.configuration.exclusion_filter[:guide_image]).to eq(expected)
    end
  end
end
