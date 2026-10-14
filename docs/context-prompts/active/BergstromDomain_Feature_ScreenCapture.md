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
* Captures live beside the app's feature specs (`spec/features/<app folder>/guide_images_spec.rb`
  — a new top-level spec folder would have no RspecMetrics::AppMapper mapping), tagged
  `guide_image: true` and **excluded from normal runs** (`filter_run_excluding`
  unless the flag is set), so the default suite and CI are unaffected.
* Run: `GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/recipes/guide_images_spec.rb`.
* Each capture names its target by `data-testid` and its output file, e.g.
  `capture_guide_image "recipe-ingredients-panel", as: "cookbook/ingredients_panel"`.
* Output: `docs/user-guide/<app>/images/<name>.png`, committed to git so the guide and its
  images are reviewed in the same PR.
* Guide Markdown references them relatively — `![The Ingredients panel](images/ingredients_panel.png)`
  — so the files also preview correctly on GitHub.
* **Serving the images (the update the app needs) — decided: Rails serves them**, through
  `GuideImagesController` (see Block 3 for why not Propshaft). Images deploy with the code
  (`docs/` is in the Docker image) and no database or Active Storage step is involved.
* Desktop only, at a fixed 1400×900 window; PNG.
* `GuidePageLoader` fails the load (all-or-nothing, like today) if a page references an image
  file that doesn't exist or has no alt text.

## 3. Feature evidence (flag: `EVIDENCE=1`)
* Purpose: for me to review during manual testing — watch the happy path in the storyboard,
  then manually test what it doesn't cover. Not evidence to keep in GitHub.
* Specs opt in with a tag naming the app and feature, e.g. `evidence: "cookbook/write_a_recipe"`
  (typically the new feature's happy-path specs). Without `EVIDENCE=1` they run as normal.
* Run: `EVIDENCE=1 bundle exec rspec spec/features/<app>/<feature>_spec.rb`.
* Output (decided): `docs/test-results/<app>/evidence/<feature>/<example>/` — numbered PNGs + an
  `index.html` storyboard (B1), beside the manual-testing rounds (`round-1.md`, …) but
  **git-ignored** (and Docker-ignored), so they stay on my machine. `<app>` uses the same folder
  names as `docs/user-guide/` (`occasions`, `chronicle`, `cookbook`). A feature-level
  `index.html` lists its examples and results. Storyboard only — no video for now.
* Size: each step is a **full-size viewport** PNG (nothing is committed, so no need to shrink);
  re-running an example replaces its folder rather than adding to it.
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
* **Done (2026-10-14).** Notes: a 1400×900 headless window gives a 1400×757 page area. Element
  and full-page captures both use Chrome's `Page.captureScreenshot` (via `execute_cdp`).
  `FailureArtifacts.save` is now a plain method (testable, reused by the after-hook). The full
  suite passed unchanged at the new window size.
* **Corrected in Block 2:** the app's layout is exactly one window high and scrolls inside
  `<main>`/the left nav, so `captureBeyondViewport` captured nothing below the window (the
  Block 1 specs had used a tall `<body>`, which the real layout never has). Captures now grow
  the window (`Emulation.setDeviceMetricsOverride`) until every scrolling area and the target
  element fit, then restore it; clips are rounded to whole pixels; captures wait for images.
  The specs now use the real layout and check the image isn't blank / reaches the element's end.

## Block 2 — User Guide capture runner
* `GUIDE_SCREENSHOTS` flag, `guide_image` tag excluded by default.
* Deterministic setup (persona, frozen time, seed data, test images, animations off).
* First capture set for one app (Cookbook) writing to `docs/user-guide/cookbook/images/`.
* **Done (2026-10-14).** `spec/support/guide_images.rb` (`capture_guide_image`) +
  `spec/features/recipes/guide_images_spec.rb` — 9 images: recipe header/details/ingredients,
  the form's title/details/ingredients panels, Browse By Cuisine, the Filter panel, the left
  nav. Photo: `docs/test-data/images/cookbook/recipes/lasagna.jpeg` (from the dev recipe).
  Added `data-testid="recipe-header"` to the recipe page header.
  Chrome's anti-aliasing can differ by a shade between runs, so an existing image is kept when
  the new capture is within 2 shades of it — re-running on an unchanged screen leaves git clean
  (checked over 3 runs).
* **Found:** `.left-nav` is `height: 100vh` but starts below the 56px top bar, so its last
  ~104px sit behind the footer and can't be scrolled into view (the Documentation › User Guide
  links on a long nav). The guide spec sets the nav's height to auto for its image; the real
  fix is a layout change, logged for a separate fix.

## Block 3 — Guide images in the app
* Serve guide images; CSS rule for guide images.
* Loader validation (missing file, missing alt); add images to one or two Cookbook guide pages
  and extend `guide_page_loader_spec.rb`.
* **Done (2026-10-14), with a change agreed at the gate:** served by `GuideImagesController`
  (`GET /user-guide/images/:app/:name.png`, public, cached with an ETag) instead of Propshaft —
  adding `docs/user-guide` to the asset paths would also have published the raw `.md` files,
  and an admin page's image folder can't be worked out at render time (admin pages sit in each
  app's folder). `GuidePageLoader` rewrites `![Alt](images/x.png)` to that route at load time,
  failing on a missing image, empty alt text or a name the route can't serve. The controller
  picks the file from the list of existing images rather than building a path from the request.
  The existing global `img { max-width: 100% }` already fits images to the page; `.guide-page-body
  img` only adds spacing (captures already carry their own border and margin).
* Images placed in Cookbook guide pages 01 (left nav), 02 (new "A Recipe's Page" section, Browse,
  Filter) and 03 (the three form panels). Also corrected 03: an ingredient row is removed with its
  × button, not a bin icon.

## Block 4 — Evidence storyboard
* `EVIDENCE` flag, `evidence: "<app>/<feature>"` tag, Capybara action hooks, numbered PNGs +
  captions, per-example and per-feature `index.html`, written to the git-ignored
  `docs/test-results/<app>/evidence/`.
* Tag the happy-path examples of `create_recipe_spec.rb` (Write A Recipe) as the first set.
* **Done (2026-10-14).** `spec/support/evidence.rb`: steps are Capybara's session actions (visit,
  click_*, fill_in, select, choose, check, uncheck, attach_file), `Element#click/set/select_option`,
  `js_click`, and `evidence_step("…", element)` for steps Capybara can't see (fields set with
  `execute_script`, as the Cookbook JS specs do for CI stability). A click inside a click
  (click_button → find → click) is one step. Captions name an element by its label/aria-label,
  then its text, then its testid. Each step waits for page loads/Turbo to settle; a named element is
  scrolled into view. Output per example: `001.png…`, `index.html`, `summary.json`; per feature: an
  `index.html` listing examples, results, step counts and when they were recorded. A failed step is
  still recorded, captioned "(failed)". `ScreenCapture.capture_window` added for window-only
  screenshots. `/docs/test-results/*/evidence/` is in `.gitignore` and `.dockerignore`.
  Open: `EVIDENCE=1 bundle exec rspec spec/features/recipes/create_recipe_spec.rb`, then
  `docs/test-results/cookbook/evidence/write_a_recipe/index.html` in a browser.

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
* Real video (B3 Playwright: `record_video_dir` + `slow_mo`, spiked on one spec first) — the
  storyboard is enough for now. Playwright traces for failing CI specs would come with it.
* MP4/GIF from storyboards via ffmpeg (not installed today).
* Running evidence specs from CI (`workflow_dispatch` input + artifact).
* Guide images for Occasions and Chronicle once Cookbook's set is reviewed.
* Annotated guide images (arrows/highlights/numbered callouts drawn on the capture).
* Image upload in the admin Guide Page form (for pages written in the app rather than in
  `docs/user-guide/`).

# DECISIONS (2026-10-14)
* **Serving guide images:** Rails serves them — Propshaft asset path + render-time rewrite
  (rejected: copying into `public/`, Active Storage attachments).
* **Window size:** desktop only, 1400×900.
* **Image format:** PNG.
* **Video:** the storyboard (B1) is enough for now; real video moved to Phase 2.
* **Evidence storage:** `docs/test-results/<app>/evidence/`, git-ignored — the storyboards are
  for reviewing during manual testing, not for keeping in GitHub (changed 2026-10-14, Block 4
  gate). Full-size PNGs.

# OPEN QUESTIONS
* None outstanding — new ones get logged here during the blocks.
