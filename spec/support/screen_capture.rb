# spec/support/screen_capture.rb

# Screenshots of a whole page or of one element (by data-testid), shared by
# failure artifacts, User Guide images and feature evidence. Both use Chrome's
# own Page.captureScreenshot: it can capture beyond the window (Selenium's
# save_screenshot stops at the viewport) and clip to an element plus a margin
# (Selenium's element screenshot can't add one). The browser runs at a fixed
# desktop size so the same page gives the same image locally and on CI.
module ScreenCapture
  class Error < StandardError; end

  WINDOW_SIZE    = [ 1400, 900 ].freeze
  ELEMENT_MARGIN = 8

  module_function

  def capture_page(path, session: Capybara.current_session)
    browser = chrome(session)
    size = browser.execute_cdp("Page.getLayoutMetrics")["cssContentSize"]
    write(path, screenshot(browser, x: 0, y: 0, width: size["width"], height: size["height"]))
  end

  # Raises Capybara::ElementNotFound (after Capybara's usual wait) when no
  # visible element has the testid. The margin is trimmed where it would run
  # off the top or left of the page.
  def capture_element(testid, path, margin: ELEMENT_MARGIN, session: Capybara.current_session)
    browser = chrome(session)
    element = session.find("[data-testid='#{testid}']")
    box = session.evaluate_script(<<~JS, element)
      (() => {
        const rect = arguments[0].getBoundingClientRect()
        return { x: rect.left + window.scrollX, y: rect.top + window.scrollY, width: rect.width, height: rect.height }
      })()
    JS
    left = [ box["x"] - margin, 0 ].max
    top  = [ box["y"] - margin, 0 ].max
    write(path, screenshot(browser, x: left, y: top,
      width: box["x"] + box["width"] + margin - left, height: box["y"] + box["height"] + margin - top))
  end

  def chrome(session)
    browser = session.driver.browser
    return browser if browser.respond_to?(:execute_cdp)

    raise Error, "Screen capture needs a browser — tag the example js: true"
  end

  def screenshot(browser, clip)
    browser.execute_cdp("Page.captureScreenshot", format: "png", captureBeyondViewport: true,
      clip: clip.merge(scale: 1))["data"]
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
