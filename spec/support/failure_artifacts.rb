# spec/support/failure_artifacts.rb

# On a failing js: true example, saves a screenshot, the page HTML, the
# browser console log and an event trace to tmp/screenshots — the folder CI's
# "Keep screenshots from failed system tests" step uploads as an artifact.
# Without this, that artifact was always empty and CI-only JS failures could
# only be guessed at.
#
# The trace comes from a small script Chrome injects into every page before
# the app's own JS runs: clicks, input/change events, submit events (and
# whether anything cancelled them), form-validation `invalid` events, every
# fetch's start/finish/failure, Turbo's submit start/end, and uncaught errors
# — enough to see where a stalled form submit actually stopped.
module FailureArtifacts
  TRACE_SCRIPT = <<~JS.freeze
    (() => {
      if (window.__trace) return
      const trace = window.__trace = []
      const log = (kind, detail) => trace.push(`${Math.round(performance.now())}ms ${kind} ${detail || ""}`)
      const describe = (el) => el && el.nodeType === 1
        ? `${el.tagName.toLowerCase()}${el.dataset.testid ? `[${el.dataset.testid}]` : ""}` : String(el)

      log("page", location.pathname)
      document.addEventListener("click", (e) => log("click", describe(e.target)), true)
      document.addEventListener("submit", (e) => log("submit:capture", describe(e.target)), true)
      window.addEventListener("submit", (e) => log("submit:bubbled", `defaultPrevented=${e.defaultPrevented}`))
      document.addEventListener("change", (e) => log("change", `${describe(e.target)} ${e.target.value}`), true)
      document.addEventListener("input", (e) => log("input", `${describe(e.target)} ${String(e.target.value).slice(0, 40)}`), true)
      document.addEventListener("invalid", (e) => log("invalid", `${describe(e.target)} ${e.target.validationMessage}`), true)
      document.addEventListener("turbo:submit-start", () => log("turbo:submit-start"))
      document.addEventListener("turbo:submit-end", (e) => log("turbo:submit-end", `success=${e.detail.success}`))
      window.addEventListener("error", (e) => log("error", e.message))
      window.addEventListener("unhandledrejection", (e) => log("unhandledrejection", String(e.reason)))

      const originalFetch = window.fetch
      window.fetch = function (input, init) {
        const url = typeof input === "string" ? input : input.url
        log("fetch:start", url)
        return originalFetch.apply(this, arguments).then(
          (response) => { log("fetch:end", `${url} ${response.status}`); return response },
          (error) => { log("fetch:error", `${url} ${error}`); throw error }
        )
      }
    })()
  JS

  # Injected once per browser session; Chrome then re-runs it on every new
  # document, so it survives visits and redirects.
  def self.install(browser)
    @installed ||= {}
    return if @installed[browser.object_id]

    browser.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source: TRACE_SCRIPT)
    @installed[browser.object_id] = true
  end
end

RSpec.configure do |config|
  config.before(:each, js: true) do
    FailureArtifacts.install(page.driver.browser)
  rescue StandardError => e
    warn "failure_artifacts: could not install the event trace: #{e.message}"
  end

  config.after(:each, js: true) do |example|
    next unless example.exception

    dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(dir)
    base = dir.join(example.full_description.parameterize.first(100)).to_s

    begin
      page.save_screenshot("#{base}.png")
      File.write("#{base}.html", page.html)
      logs = page.driver.browser.logs.get(:browser).map { |entry| "#{entry.level} #{entry.message}" }
      trace = page.evaluate_script("window.__trace || []")
      File.write("#{base}.log", ([ "path: #{page.current_path}" ] + logs + [ "", "trace:" ] + trace).join("\n"))
    rescue StandardError => e
      warn "failure_artifacts: could not save artifacts for #{example.full_description}: #{e.message}"
    end
  end
end
