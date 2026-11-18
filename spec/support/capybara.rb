# spec/support/capybara.rb
Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=#{ScreenCapture::WINDOW_SIZE.join(',')}")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :chrome_headless

# Capybara 3.40 resets Chrome between examples with
# Storage.clearDataForOrigin(origin: "*"). Chrome 158 refuses "*" as not a valid
# URL, so every js example failed in its after hook. When Chrome refuses it,
# clear the cookies, and local storage for the app's own origin, instead.
module ChromeWildcardStorageClear
  private

  def execute_cdp(cmd, params = {})
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError
    raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    origin = Capybara.current_session.server&.base_url
    super("Storage.clearDataForOrigin", origin: origin, storageTypes: "local_storage") if origin && params[:storageTypes].to_s.include?("local_storage")
  end
end
require "capybara/selenium/driver"
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeWildcardStorageClear)
