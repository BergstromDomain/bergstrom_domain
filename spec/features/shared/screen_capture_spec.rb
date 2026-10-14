# spec/features/shared/screen_capture_spec.rb
require "rails_helper"

RSpec.describe "Screen Capture", type: :feature do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(directory) }

  # Width and height straight from the PNG's IHDR chunk — no image library needed.
  def png_size(path)
    File.binread(path, 8, 16).unpack("N2")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path", js: true do
    it "Runs the browser at the fixed 1400px desktop width" do
      visit contact_path

      expect(page.evaluate_script("window.innerWidth")).to eq(ScreenCapture::WINDOW_SIZE.first)
    end

    it "Captures the whole page, including what is below the window" do
      visit contact_path
      page.execute_script("document.body.style.minHeight = '2000px'")
      page_width = page.evaluate_script("document.documentElement.clientWidth") # the window less its scrollbar

      path = capture_page(directory.join("contact.png"))

      width, height = png_size(path)
      expect(width).to eq(page_width)
      expect(height).to be >= 2000
    end

    it "Captures one element by its testid, with a margin around it" do
      visit contact_path
      box = page.evaluate_script("document.querySelector('[data-testid=\"contact-panel\"]').getBoundingClientRect().toJSON()")

      path = capture_element("contact-panel", directory.join("panel.png"))

      margin = ScreenCapture::ELEMENT_MARGIN * 2
      expect(png_size(path)).to eq([ (box["width"] + margin).ceil, (box["height"] + margin).ceil ])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Fails clearly when the example has no browser to capture from" do
      visit contact_path

      expect { capture_page(directory.join("contact.png")) }
        .to raise_error(ScreenCapture::Error, /js: true/)
    end

    it "Fails when no element has the testid", js: true do
      visit contact_path

      expect { capture_element("no-such-testid", directory.join("missing.png")) }
        .to raise_error(Capybara::ElementNotFound)
      expect(directory.children).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path", js: true do
    it "Captures an element below the window without scrolling the page first" do
      visit contact_path
      page.execute_script(<<~JS)
        const spacer = document.createElement("div")
        spacer.style.height = "1500px"
        document.querySelector('[data-testid="contact-panel"]').before(spacer)
      JS
      box = page.evaluate_script("document.querySelector('[data-testid=\"contact-panel\"]').getBoundingClientRect().toJSON()")

      path = capture_element("contact-panel", directory.join("panel.png"), margin: 0)

      expect(png_size(path)).to eq([ box["width"].ceil, box["height"].ceil ])
    end

    it "Creates missing folders on the way to the file" do
      visit contact_path

      path = capture_page(directory.join("occasions/images/contact.png"))

      expect(path).to be_file
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases", js: true do
    it "Keeps the margin inside the page for an element at the top-left corner" do
      visit contact_path
      page.execute_script(<<~JS)
        const box = document.createElement("div")
        box.dataset.testid = "corner-box"
        box.style.cssText = "position:absolute; top:0; left:0; width:100px; height:50px; background:red"
        document.body.append(box)
      JS

      path = capture_element("corner-box", directory.join("corner.png"))

      expect(png_size(path)).to eq([ 100 + ScreenCapture::ELEMENT_MARGIN, 50 + ScreenCapture::ELEMENT_MARGIN ])
    end
  end
end
