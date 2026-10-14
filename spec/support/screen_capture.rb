# spec/support/screen_capture.rb

# Screenshots of a whole page or of one element (by data-testid), shared by
# failure artifacts, User Guide images and feature evidence. Both use Chrome's
# own Page.captureScreenshot: it can clip to an element plus a margin
# (Selenium's element screenshot can't add one). The browser runs at a fixed
# desktop size so the same page gives the same image locally and on CI.
#
# The app's layout is exactly one window high and scrolls inside <main> (and
# the left nav), so anything below the window isn't drawn at all — Chrome's
# captureBeyondViewport doesn't help. While capturing, the window is made
# tall enough for every scrolling area to fit, then put back.
module ScreenCapture
  class Error < StandardError; end

  WINDOW_SIZE    = [ 1400, 900 ].freeze
  ELEMENT_MARGIN = 8
  # Chrome can't draw a taller image than this in one go.
  MAX_HEIGHT     = 16_384

  # How much taller the window must be for the page, every area that scrolls
  # on its own, and the element being captured (arguments[0], if any — it can
  # run past the window without anything scrolling) to show in full.
  HIDDEN_HEIGHT_SCRIPT = <<~JS.freeze
    (() => {
      let hidden = document.documentElement.scrollHeight - window.innerHeight
      if (arguments[0]) hidden = Math.max(hidden, arguments[0].getBoundingClientRect().bottom + arguments[1] - window.innerHeight)
      for (const el of document.querySelectorAll("*")) {
        const overflowY = getComputedStyle(el).overflowY
        if ((overflowY === "auto" || overflowY === "scroll") && el.scrollHeight > el.clientHeight) {
          hidden = Math.max(hidden, el.scrollHeight - el.clientHeight)
        }
      }
      return Math.max(hidden, 0)
    })()
  JS

  module_function

  def capture_page(path, session: Capybara.current_session)
    showing_everything(session) do |browser, width, height|
      write(path, screenshot(browser, x: 0, y: 0, width: width, height: height))
    end
  end

  # Just the window, as a person would see it — for evidence storyboards.
  def capture_window(path, session: Capybara.current_session)
    write(path, chrome(session).execute_cdp("Page.captureScreenshot", format: "png")["data"])
  end

  # Raises Capybara::ElementNotFound (after Capybara's usual wait) when no
  # visible element has the testid. The margin is trimmed where it would run
  # off the top or left of the page.
  def capture_element(testid, path, margin: ELEMENT_MARGIN, session: Capybara.current_session)
    element = session.find("[data-testid='#{testid}']")
    wait_for_images(session)
    showing_everything(session, element, margin) do |browser|
      box = session.evaluate_script(<<~JS, element)
        (() => {
          const rect = arguments[0].getBoundingClientRect()
          return { x: rect.left + window.scrollX, y: rect.top + window.scrollY, width: rect.width, height: rect.height }
        })()
      JS
      # Whole pixels: a clip starting part-way into a pixel is resampled, and
      # the same element can then come out a shade different on a re-run.
      left   = [ (box["x"] - margin).floor, 0 ].max
      top    = [ (box["y"] - margin).floor, 0 ].max
      right  = (box["x"] + box["width"] + margin).ceil
      bottom = (box["y"] + box["height"] + margin).ceil
      write(path, screenshot(browser, x: left, y: top, width: right - left, height: bottom - top))
    end
  end

  # Grows the window until nothing is hidden (growing one scrolling area can
  # reveal another), yields the browser and the window's size, then restores it.
  # Gives up after a few rounds, for something that grows with the window.
  def showing_everything(session, element = nil, margin = 0)
    browser = chrome(session)
    width, height = session.evaluate_script("[window.innerWidth, window.innerHeight]")
    3.times do
      hidden = session.evaluate_script(HIDDEN_HEIGHT_SCRIPT, element, margin).ceil
      break if hidden <= 0 || height >= MAX_HEIGHT

      height = [ height + hidden, MAX_HEIGHT ].min
      browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: height,
        deviceScaleFactor: 1, mobile: false)
    end
    yield browser, width, height
  ensure
    browser&.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  # A half-loaded photo would be captured as it was at that moment.
  def wait_for_images(session)
    Capybara.using_wait_time(5) do
      session.document.synchronize do
        loaded = session.evaluate_script("Array.from(document.images).every((img) => img.complete)")
        raise Capybara::ExpectationNotMet, "images still loading" unless loaded
      end
    end
  end

  def chrome(session)
    browser = session.driver.browser
    return browser if browser.respond_to?(:execute_cdp)

    raise Error, "Screen capture needs a browser — tag the example js: true"
  end

  def screenshot(browser, clip)
    browser.execute_cdp("Page.captureScreenshot", format: "png", clip: clip.merge(scale: 1))["data"]
  end

  def write(path, base64_png)
    path = Pathname.new(path)
    FileUtils.mkdir_p(path.dirname)
    path.binwrite(Base64.decode64(base64_png))
    path
  end
end

RSpec.configure do |config|
  config.include ScreenCapture, type: :feature
end
