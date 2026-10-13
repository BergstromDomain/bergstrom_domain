# TASK
* Plan the development of a **Screen Capture** feature to be added to **Global — shared across
  BergstromDomain** (test tooling, not a user-facing page).
* **Confirmation gate:** before starting a new development block, summarise what you know so far
  (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open
  design questions before progressing. Do not skip ahead to implementation on an unconfirmed
  block.
* Follow existing project conventions without restating them here: TDD (Red → Green →
  Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the
  `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop →
  rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.
* **Naming:** this doc follows the new `docs/context-prompts/` naming convention —
  `BergstromDomain_Feature_<Name>.md` for cross-cutting features, `<App>_Feature_<Name>.md` for
  app-specific ones (e.g. `Occasions_Feature_Family.md`), `<App>_App.md`, `<App>_ToDos.md`. That
  rename is part of the docs reorganisation that **has not been committed yet** (it is still
  uncommitted on `main`). Refer to other docs by their new names, and don't commit the
  reorganisation as part of this feature; it goes in on its own when asked.

---

# FEATURE DESCRIPTION
Three uses for capturing what the browser shows, each from the developer's/author's point of
view:

1. **Failure images (debugging).** When an automated browser test fails, keep a picture of what
   the page looked like so the cause can be seen rather than guessed — locally and from CI.
   *Always on* for failing tests.
2. **User Guide images.** Capture clean, repeatable screenshots of pages or single components
   (a panel, a form, the left nav) and show them in the User Guide pages
   (`docs/user-guide/<app>/*.md`). *Off by default*; run on demand with an execution flag when
   the guide is being written or a screen has changed.
3. **Feature evidence videos.** Record a video of a new feature being exercised end-to-end, as
   evidence for a PR and to speed up manual testing (watch the happy path instead of clicking
   it all by hand, then manually test only what the video doesn't cover). *Off by default*;
   run on demand with an execution flag.

---

# SCOPE
* **Global** — test tooling plus a small rendering change to `GuidePage`; usable by every app.
* **Existing pattern audit:**
  * `spec/support/failure_artifacts.rb` already saves a **viewport screenshot**, the page HTML,
    the browser console log and an event trace to `tmp/screenshots/` for every failing
    `js: true` example. CI's "Keep screenshots from failed system tests" step
    (`.github/workflows/ci.yml`) uploads that folder as the `screenshots` artifact. Use case 1 is
    therefore mostly built — this feature extends it rather than replacing it.
  * `spec/support/capybara.rb` registers a single `:chrome_headless` **Selenium** driver with no
    window size set (Chrome's headless default), so screenshot dimensions aren't fixed today.
  * **Ferrum** (`gem "ferrum", "~> 0.18.0"`) is already a dependency, used by
    `PdfRenderingService` for HTML → PDF. Ferrum 0.18 can also take selector screenshots and
    record a CDP screencast (`page.start_screencast`/`stop_screencast`).
  * Selenium 4.51's `WebElement` supports `save_screenshot`, i.e. **element screenshots** —
    exactly what Robot Framework's SeleniumLibrary `Capture Element Screenshot` keyword does
    under the hood. No new gem is needed to capture individual divs.
  * `GuidePage` renders Markdown through `MarkdownRenderable` (Commonmarker), and its sanitizer
    allowlist **already permits `img` with `src`/`alt`**. What's missing for guide images is a
    place to *serve* the image files from, a way to point Markdown at them, and the loader
    checking that every referenced image exists.
  * `capybara-screenshot-diff` was suggested earlier (Cookbook work) for capturing guide
    screenshots and flagging visual changes — evaluated below.
  * Uses Selenium-specific APIs today (would need care under any driver change):
    `failure_artifacts.rb` (`execute_cdp`, `browser.logs`), `confirm_dialog_spec.rb`,
    `filter_blog_posts_spec.rb`, `likes_breakdown_popup_spec.rb`, and the shared `js_click`
    helper.
* **Touches:** `spec/support/`, `.rspec`/RSpec config (tags + exclusion), `.github/workflows/ci.yml`,
  `GuidePage`/`GuidePageLoader`/guide view CSS, `docs/user-guide/<app>/`, `.gitignore`.
* **Excluded:** no in-app (end-user) screen recording or screenshot feature — this is
  developer/author tooling only. Photo_Album and future apps get it for free once they have
  feature specs.

---

# OPTIONS
Tooling available on this machine today: Chrome (via Selenium), Ferrum, Node/npx, Xvfb.
**ffmpeg is not installed** (it is needed by several video options below).

## A. Images (failure + User Guide)

| # | Option | How | For | Against |
|---|--------|-----|-----|---------|
| A1 | **Selenium element/page screenshots** (recommended) | `find("[data-testid=…]").native.save_screenshot(path)`; full-page via `execute_cdp("Page.captureScreenshot", captureBeyondViewport: true)` | No new gem, no driver change; same mechanism as Robot Framework's element capture; reuses existing personas, factories and specs | We write the small helper ourselves (naming, output folder, padding around an element) |
| A2 | `capybara-screenshot-diff` | `screenshot "name", crop: "[data-testid=…]"` in specs; stores baselines, fails/reports when a screenshot changes | Element crops plus **visual regression**: tells you which guide images went stale after a UI change | Baselines are pixel-sensitive (fonts, anti-aliasing differ between local and CI); designed around "fail on diff", which is noise for guide images unless only run on demand |
| A3 | `capybara-screenshot` gem | Auto-saves screenshot + HTML on failure | Zero code | Duplicates what `failure_artifacts.rb` already does better (console log + event trace) — **not recommended** |
| A4 | Ferrum/Cuprite screenshots | `page.screenshot(selector: …)` | Clean API, full-page built in | Only reachable if specs move to the Cuprite driver (see B2) |

## B. Video (feature evidence)

| # | Option | How | For | Against |
|---|--------|-----|-----|---------|
| B1 | **Step storyboard** (screenshot after every Capybara action) | Wrap `visit`/`click_*`/`fill_in`/`select` to save a numbered screenshot + caption; write an HTML page per spec, optionally stitched into MP4/GIF with ffmpeg | Works with today's Selenium driver; deterministic; **easier to review than video** (each step is one frame with its caption, no scrubbing); tiny files; doubles as rich failure evidence | Not real motion — animations, toasts and hover states between steps aren't seen; true video needs ffmpeg |
| B2 | **Cuprite driver + Ferrum screencast** | Run `:evidence` specs on Cuprite (Ferrum-based Capybara driver); `start_screencast` emits JPEG frames; ffmpeg assembles them | Ferrum already a dependency; real motion; per-spec | New driver for those specs (Selenium-only APIs above don't port); frames only arrive when the page changes, so timing needs stitching with timestamps; needs ffmpeg |
| B3 | **Playwright driver** (`capybara-playwright-driver` + `playwright-ruby-client`) | `record_video_dir:` on the browser context — one `.webm` per spec, no ffmpeg; `slow_mo:` to make it watchable | Best video with least code; also gives **Playwright traces** (step-by-step DOM snapshots + network, viewed in the trace viewer) — the strongest failure-debugging tool of all the options | Second browser stack (Node package + `npx playwright install chromium`) alongside Selenium, locally and in CI; same porting caveat as B2 for Selenium-only APIs |
| B4 | Screen recording of a headed browser | Run Chrome headed inside Xvfb and record the display with `ffmpeg -f x11grab` (the Robot Framework ScreenCapLibrary approach) | Records exactly what a human would see, including timing | Heaviest and most brittle (display numbers, window placement, Linux-only); needs ffmpeg; records idle time too |

## Recommendation
* **Images:** A1 (Selenium element/page screenshots) for both failure images and User Guide
  images. Revisit A2 (`capybara-screenshot-diff`) in Phase 2 only as a "which guide images are
  stale?" report, run on demand, never as a failing check.
* **Video:** start with **B1 (storyboard)** — it needs no new driver, and for "did the feature
  do what it should?" review it's faster to scan than a video. If real motion turns out to
  matter, add **B3 (Playwright)** for `:evidence` specs only; prefer it over B2 because it
  produces video natively and adds traces. B4 is not recommended.

---

# DESIGN GUIDELINES
- Nothing user-facing beyond guide images — no new design tokens. Guide images get one CSS rule
  in `application.css` (max-width: 100%, a subtle border matching `.show-panel`) — the only
  stylesheet actually served.
- Captures must be **deterministic** so a re-run produces the same image: fixed browser window
  size, fixed persona (e.g. Charlie Content Creator), fixed seed data with fixed names and
  dates (travel_to a fixed date), images from `docs/test-data/images/<app>/<entity>/`, and
  animations/transitions disabled while capturing.
- Accessibility: every guide image needs meaningful `alt` text in the Markdown; the loader
  rejects an image with empty alt.
- Classification: guide screenshots must only show test data — never real dev/PROD records.

---

# BEHAVIOUR SPEC
## 1. Failure images (always on)
* Trigger: any failing `js: true` example (as today).
* Output: `tmp/screenshots/<example>.png` (+ existing `.html` and `.log`), uploaded by CI.
* Change: make the screenshot **full page**, not just the viewport, and fix the window size so
  images are comparable between local and CI runs.
* Non-JS (`rack_test`) failures have no browser, so no image is possible — save the HTML only.

## 2. User Guide images (flag: `GUIDE_SCREENSHOTS=1`)
* Captures live in their own spec folder (e.g. `spec/guide_screenshots/<app>_spec.rb`),
  tagged `guide_screenshot: true` and **excluded from normal runs** (`filter_run_excluding`
  unless the flag is set), so the default suite and CI are unaffected.
* Run: `GUIDE_SCREENSHOTS=1 bundle exec rspec spec/guide_screenshots` (optionally one app).
* Each capture names its target by `data-testid` and its output file, e.g.
  `capture_guide_image "recipe-ingredients-panel", as: "cookbook/ingredients_panel"`.
* Output: `docs/user-guide/<app>/images/<name>.png`, committed to git so the guide and its
  images are reviewed in the same PR.
* Guide Markdown references them relatively — `![The Ingredients panel](images/ingredients_panel.png)`
  — so the files also preview correctly on GitHub.
* **Serving the images (the update the app needs):** recommended approach — add the guide image
  folders to Propshaft's asset paths and, when rendering a `GuidePage`, rewrite
  `images/<name>.png` to its digested `/assets/...` URL. Images then deploy with the code and
  are cache-busted like any other asset, and no database or Active Storage step is involved.
  Alternatives logged under Open Questions.
* `GuidePageLoader` fails the load (all-or-nothing, like today) if a page references an image
  file that doesn't exist or has no alt text.

## 3. Feature evidence (flag: `EVIDENCE=1`)
* Specs opt in with an `:evidence` tag (typically the new feature's happy-path specs).
* Run: `EVIDENCE=1 bundle exec rspec spec/features/<app>/<feature>_spec.rb`.
* Output: `tmp/evidence/<branch>/<spec>/` — numbered PNGs + `index.html` storyboard (B1); with
  ffmpeg present, also `<spec>.mp4`. Not committed (size); attached to the PR by hand, or
  uploaded as a CI artifact when a manually triggered workflow run sets the flag.
* Captions come from the Capybara action ("Click Save Recipe", "Fill in Title with …") so the
  storyboard reads like the test.
* Edge cases: a failing evidence spec still writes its storyboard up to the failure; a spec
  that opens a new window/tab captures only the current one; flags are ignored for
  non-`js: true` specs (nothing to capture).

---

# INTEGRATION / MIGRATION
* Call sites to retrofit onto the new pattern:
  * [ ] `spec/support/failure_artifacts.rb` — full-page screenshot, share the window-size
        setting and output helpers with the new capture code
  * [ ] `spec/support/capybara.rb` — fixed `--window-size` for `:chrome_headless`
  * [ ] `.github/workflows/ci.yml` — optional `workflow_dispatch` input to run evidence specs
        and upload `tmp/evidence` as an artifact
  * [ ] `app/models/guide_page.rb` / `GuidePagesHelper` — image path rewrite at render time
  * [ ] `app/services/guide_page_loader.rb` — missing-image / missing-alt validation
* Rollout: incremental — failure images first (lowest risk), then guide images (one app first,
  e.g. Cookbook), then evidence.
* Must keep working unchanged: the full default suite and CI timings (all capture beyond
  failures is behind flags), the existing CI `screenshots` artifact, and guide pages without
  images.
* **Risk:** fixing the window size can change layout for existing `js: true` specs that
  currently pass at Chrome's default size — run the full feature suite in the block that
  introduces it.

---

# DEVELOPMENT BLOCKS

## Block 1 — Shared capture helper + better failure images
* `spec/support/screen_capture.rb`: `capture_page(path)` (full page via CDP) and
  `capture_element(testid, path)` (element screenshot, small padding).
* Fixed window size in `capybara.rb`; full-page screenshot in `failure_artifacts.rb`; HTML-only
  artifact for failing non-JS specs.

## Block 2 — User Guide capture runner
* `GUIDE_SCREENSHOTS` flag, `guide_screenshot` tag excluded by default, `spec/guide_screenshots/`.
* Deterministic setup helper (persona, frozen time, seed data, test images, animations off).
* First capture set for one app (Cookbook) writing to `docs/user-guide/cookbook/images/`.

## Block 3 — Guide images in the app
* Serve guide images (Propshaft path + render-time rewrite, or the option chosen in Open
  Questions); CSS rule for guide images.
* Loader validation (missing file, missing alt); add images to one or two Cookbook guide pages
  and extend `guide_page_loader_spec.rb`.

## Block 4 — Evidence storyboard
* `EVIDENCE` flag, `:evidence` tag, Capybara action hooks, numbered PNGs + captions, `index.html`.
* Optional MP4/GIF via ffmpeg when available (skipped with a notice when not).
* Optional CI `workflow_dispatch` input + `tmp/evidence` artifact.

## Block 5 (only if needed) — Real video via Playwright
* Spike first: run one Cookbook happy-path spec under `capybara-playwright-driver` with
  `record_video_dir` and `slow_mo`; decide from the result whether to adopt it for `:evidence`
  specs (and traces for failures).

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format (`Main:` — this is cross-cutting)
* Default suite and CI unchanged in duration when no flag is set
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
* `capybara-screenshot-diff` as an on-demand "stale guide images" report.
* Playwright traces for failing CI specs (only if Block 5 is adopted).
* Guide images for Occasions and Chronicle once Cookbook's set is reviewed.
* Annotated guide images (arrows/highlights/numbered callouts drawn on the capture).
* Image upload in the admin Guide Page form (for pages written in the app rather than in
  `docs/user-guide/`).

# OPEN QUESTIONS
* **Serving guide images** — Propshaft asset path + render-time rewrite (recommended), copy
  into `public/user-guide/` at load time (simplest, but un-digested and duplicated), or Active
  Storage attachments on `GuidePage` created by the loader (works with uploads later, but puts
  versioned docs in the database/storage volume)?
* **Window size** for captures — desktop only (e.g. 1400×900), or also a phone-width set for
  the guide?
* **Image format** — PNG (lossless, larger) or WebP (smaller; libvips is already installed to
  convert)?
* **Video** — is the storyboard (B1) enough as evidence, or is real motion (B3 Playwright)
  wanted from the start? If video: install ffmpeg locally (`sudo apt install ffmpeg`) and in CI?
* **Evidence storage** — attach to the PR by hand, CI artifact only, or keep selected evidence
  under `docs/test-results/<app>/` alongside the manual-testing rounds?
