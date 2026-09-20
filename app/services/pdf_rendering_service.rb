# app/services/pdf_rendering_service.rb

# App-agnostic HTML-to-PDF renderer (Ferrum drives headless Chrome directly via
# the DevTools Protocol — no Node/npm/Puppeteer dependency, unlike Grover).
# Callers must hand over fully self-contained HTML (inline styles, inline/data-
# URI images) — this service never navigates anywhere, so it has no browsing
# context/origin to resolve a relative asset URL against.
class PdfRenderingService
  def initialize(html, format: :A4)
    @html   = html
    @format = format
  end

  def render
    raise ArgumentError, "html can't be blank" if @html.blank?

    browser = Ferrum::Browser.new(headless: true)
    page = browser.create_page
    page.content = @html
    page.pdf(format: @format, encoding: :binary)
  ensure
    browser&.quit
  end
end
