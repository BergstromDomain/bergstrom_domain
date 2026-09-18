# spec/support/js_click_helper.rb

# Capybara's native Selenium `.click` was found, via a capture-phase
# click/submit listener, to occasionally dispatch *no* DOM event at all —
# not "wrong element," not "prevented," literally zero events reaching a
# document-level listener. Confirmed as a WebDriver-level click-dispatch
# flakiness (not a Turbo/app bug): the page never navigated away, and
# switching to a JS-dispatched click eliminated it. Seen on more than just
# the first click after a page load — any js: true spec doing a
# Capybara-driven `.click` on a button/link should prefer this helper.
# .focus() first matters: a bare synthetic `.click()` doesn't move focus
# the way a real click does — some specs (e.g. dialog focus-return-to-
# trigger) depend on that.
#
# Only safe when `testid` is unique in the DOM at click time — this uses
# document.querySelector, which returns the first match, not a
# Capybara-scoped one. For a testid that repeats (e.g. one row among
# several identical ones), scope to a unique ancestor testid first, or
# fall back to Capybara's native `.click` for that case.
module JsClickHelper
  def js_click(testid)
    page.execute_script(<<~JS)
      const el = document.querySelector('[data-testid="#{testid}"]')
      el.focus()
      el.click()
    JS
  end
end
