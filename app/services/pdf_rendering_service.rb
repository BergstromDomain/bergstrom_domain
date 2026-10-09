# app/services/pdf_rendering_service.rb

# App-agnostic HTML-to-PDF renderer (Ferrum drives headless Chrome directly via
# the DevTools Protocol — no Node/npm/Puppeteer dependency, unlike Grover).
# Callers must hand over fully self-contained HTML (inline styles, inline/data-
# URI images) — this service never navigates anywhere, so it has no browsing
# context/origin to resolve a relative asset URL against.
class PdfRenderingService
  # Chrome's print-to-PDF footer template is plain inline-styled HTML (no
  # external stylesheet access) rendered once per page via CDP, not part of
  # the page's own content flow — this is how every PDF gets a repeating
  # "BergstromDomain" footer without the content template having to know
  # about pagination itself. `header_template` is set to an empty span to
  # suppress Chrome's own default header (date/title/url), since only a
  # footer was asked for.
  FOOTER_TEMPLATE = <<~HTML
    <div style="width: 100%; font-size: 8px; color: #6b6460; text-align: center;
                font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;">
      BergstromDomain &middot; Page <span class="pageNumber"></span> of <span class="totalPages"></span>
    </div>
  HTML
  EMPTY_HEADER_TEMPLATE = "<span></span>".freeze

  def initialize(html, format: :A4)
    @html   = html
    @format = format
  end

  def render
    raise ArgumentError, "html can't be blank" if @html.blank?

    browser = Ferrum::Browser.new(headless: true)
    page = browser.create_page
    page.content = @html
    page.pdf(format: @format, encoding: :binary,
              display_header_footer: true,
              header_template:       EMPTY_HEADER_TEMPLATE,
              footer_template:       FOOTER_TEMPLATE,
              margin_bottom:         0.5)
  ensure
    browser&.quit
  end
end
