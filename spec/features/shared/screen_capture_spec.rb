# spec/features/shared/screen_capture_spec.rb
require "rails_helper"

RSpec.describe "Screen Capture", type: :feature do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(directory) }

  # Width and height straight from the PNG's IHDR chunk — no image library needed.
  def png_size(path)
    File.binread(path, 8, 16).unpack("N2")
  end

  # A capture of something off-screen comes out as (nearly) one flat colour.
  def blank?(path)
    image = vips(path)
    image.max - image.min < 16
  end

  # Whether the bottom rows of the capture are red — the red bottom border an
  # example gave the element, so the capture reached the element's very end.
  def red_at_the_bottom?(path)
    image = vips(path)
    red, green, blue = image.crop(0, image.height - 10, image.width, 10).bandsplit.first(3).map(&:avg)
    red > 240 && green < 15 && blue < 15
  end

  def vips(path)
    require "vips"
    Vips::Image.new_from_file(path.to_s)
  end

  # The app's layout is one window high and scrolls inside <main>, so content
  # added there (not to <body>) is what ends up below the window.
  def push_below_the_window(testid, by: 1500)
    page.execute_script(<<~JS)
      const spacer = document.createElement("div")
      spacer.style.height = "#{by}px"
      document.querySelector('[data-testid="#{testid}"]').before(spacer)
    JS
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path", js: true do
    it "Runs the browser at the fixed 1400px desktop width" do
      visit contact_path

      expect(page.evaluate_script("window.innerWidth")).to eq(ScreenCapture::WINDOW_SIZE.first)
    end

    it "Captures the whole page, including what is below the window" do
      visit contact_path
      push_below_the_window("contact-panel")

      path = capture_page(directory.join("contact.png"))

      width, height = png_size(path)
      expect(width).to eq(ScreenCapture::WINDOW_SIZE.first)
      expect(height).to be > 1500
    end

    it "Captures one element by its testid, with a margin around it" do
      visit contact_path
      box = page.evaluate_script("document.querySelector('[data-testid=\"contact-panel\"]').getBoundingClientRect().toJSON()")

      path = capture_element("contact-panel", directory.join("panel.png"))

      margin = ScreenCapture::ELEMENT_MARGIN * 2
      expect(png_size(path)).to eq([ (box["width"] + margin).ceil, (box["height"] + margin).ceil ])
      expect(blank?(path)).to be(false)
    end

    it "Puts the window back to its normal size afterwards" do
      visit contact_path
      push_below_the_window("contact-panel")
      height = page.evaluate_script("window.innerHeight")

      capture_page(directory.join("contact.png"))

      expect(page.evaluate_script("window.innerHeight")).to eq(height)
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
      push_below_the_window("contact-panel")
      box = page.evaluate_script("document.querySelector('[data-testid=\"contact-panel\"]').getBoundingClientRect().toJSON()")

      path = capture_element("contact-panel", directory.join("panel.png"), margin: 0)

      expect(png_size(path)).to eq([ box["width"].ceil, box["height"].ceil ])
      expect(blank?(path)).to be(false)
    end

    it "Captures an element taller than the window in full" do
      visit contact_path
      page.execute_script(<<~JS)
        const panel = document.querySelector('[data-testid="contact-panel"]')
        panel.style.cssText += "; box-sizing: border-box; height: 2000px; border-bottom: 40px solid rgb(255, 0, 0)"
      JS

      path = capture_element("contact-panel", directory.join("panel.png"), margin: 0)

      expect(png_size(path).last).to eq(2000)
      expect(red_at_the_bottom?(path)).to be(true)
    end

    it "Creates missing folders on the way to the file" do
      visit contact_path

      path = capture_page(directory.join("occasions/images/contact.png"))

      expect(path).to be_file
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases", js: true do
    it "Captures an element that runs past the window without making anything scroll" do
      visit contact_path
      page.execute_script(<<~JS)
        const box = document.createElement("div")
        box.dataset.testid = "fixed-box"
        box.style.cssText = "position:fixed; top:600px; left:0; width:100px; height:400px; box-sizing:border-box; " +
          "background:white; border-bottom:40px solid rgb(255, 0, 0)"
        document.body.append(box)
      JS

      path = capture_element("fixed-box", directory.join("fixed.png"), margin: 0)

      expect(png_size(path)).to eq([ 100, 400 ])
      expect(red_at_the_bottom?(path)).to be(true)
    end

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
