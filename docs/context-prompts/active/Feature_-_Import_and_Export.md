# TASK
* Plan the development of the Import and Export feature to be added to Chronicle and later on Cookbook and future apps.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
There are several different downloads and imports required
* Show page
  * Add a 'Download PDF' button
  * This should allow the user to download a PRD version of the current blog post
  * No additional permissions to check, if the user can read the post, he/she can download a PDF version
  * The content should be saved as an A4 document in PDF format 
  * The post title should be used as the file name but replace spaces with underscore

* Import & Export >> Download Blog Posts
  * New page (actually this might already exist but has been hidden) 
  * Page to look like 'Filter Blog Post' but with an 'Action Panel' at the bottom
    * 'Download PDFs' button
    * Clicking on the button should 
	1) Ask for confirmation that the user wants to download these [NUMBER] of posts
           [NUMBER] = The results from the filters above
    	2) Download a zip-file with the PDFs of the posts
    	   The individual PDFs should be as from the Show page, i.e. this is just several downloads in one

* Import & Export >> Download Blog Posts
  * Use Case: As part of my testing I'm planning to import/create several 'real' posts which I will edit and tweak together with the app development itself. Once I'm done, I want a way to export these posts into a format which can later on be imported into the PROD version of the site
  * In the 'Action Panel', add 'Download [XXX]' button - This should only be available for Admins
    [XXX] = The required format. Tar file with data files and images? XML? Other?


* Import & Export >> Import Blog Posts [XXX]
  * Page to import the blog posts exported above 
  * This should only be available for Admins

* Import & Export >> Import Blog Posts 
  * Suggest a few options to assist the users to import blog posts
    * Word
	If/when text only >> Convert to Markdown
	If/when images and table >> Exclude and inform the user that images have to be added manually
    * Excel
        Provide a CSV template allowing the user to import unformatted text
  * Provide links to online tools to convert Office docs to Markdown 


---

# SCOPE
* Global 

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC

**1. Show page "Download PDF" button**
* Visible to anyone who can already read the post (`Policy#can_read?` — no extra check).
* Renders the post as an A4 PDF via a headless-Chrome PDF gem (Grover), reusing the existing
  Show page HTML/CSS (including the `@media print` rules already built for the hidden
  print-to-PDF flow) rather than a separate hand-built layout.
* Filename: post title with spaces replaced by underscores (e.g. `Isaac_Newton.pdf`).

**2. "Download Blog Posts" page (rebuild of the hidden `BlogExportsController`)**
* Same filter UI/engine as "Filter Blog Posts" (`BlogPostFilter`/Jql), so the same Basic/SQL
  modes and result set apply.
* A `show-panel--actions` "Action Panel" at the bottom of the results, with a "Download PDFs"
  button.
* Clicking it: (a) confirms via the existing global Confirm Dialog — "Download these [N] posts?"
  where N = the current filtered result count; (b) on confirm, streams a zip file containing one
  PDF per post (each identical to what the Show page's own "Download PDF" produces).
* Existing plain CSV export (`BlogPostExportService`) and print view stay as-is unless the
  redesign naturally subsumes them (decide when this block starts).

**3. Import Blog Posts — CSV path**
* Mirrors Event_Tracker's `ImportService`/`ImportTemplateService`/`Result` pattern: a
  downloadable CSV template, row-per-post import with per-row transactions, a `Result`
  (imported/failed counts + per-row errors) rendered back to the user.
* Chronicle-specific header row (title/category/subject/topic/body/...); body arrives as plain
  text (no formatting) subject to a spreadsheet-cell character ceiling (~32K, well above a
  ~500-word post) — this is the "Alt 3" workflow from the design discussion.
* Imported posts land as Drafts (unpublished) so the importing user can review/edit before
  publishing — confirm this default when the block starts.

**4. Import Blog Posts — Zip package path**
* A generic "post package" zip: one or more posts, each with its Markdown body plus its actual
  image files, tied together by a manifest (JSON or CSV — decide at block start).
* Two producers of this same format: (a) a user follows a linked external Word→Markdown+images
  converter tool and uploads the resulting zip ("Alt 2" from the design discussion); (b) later,
  this same format is the natural candidate for the admin PROD-migration export/import use case
  (former Open Questions #2/#3) — **decide at Block 4's start whether a separate admin wrapper
  block is still needed, or whether this import page alone (behind the existing `can_export?`
  gate, or a stricter `can_administer?` gate if warranted) already covers it.**

**Cross-cutting: core service layer**
* Per the confirmed "Global" scope, the underlying PDF-rendering and zip-bundling services are
  built with zero Chronicle/BlogPost-specific knowledge (mirroring how `Jql::Evaluator` has zero
  BlogPost knowledge) — a thin Chronicle-specific glue layer (what to render, which posts, what
  filename) sits on top, so Cookbook and eventually Event_Tracker/Occasions can reuse the same
  core services without a rewrite.

# INTEGRATION / MIGRATION
* The existing hidden `BlogExportsController` + routes (`blog-posts/export`, `.../print`,
  `.../csv`) + `BlogPostExportService` + views are the base to rebuild Block 2 into, not a
  separate parallel page — confirm at Block 2's start if you'd rather keep the current
  print/CSV-only version as a distinct simpler page instead.
* Event_Tracker's `ExportService`/`ImportService`/`ImportTemplateService` are the pattern
  reference for Block 3 (CSV import), not shared code directly (they're Person/Event-specific)
  — Chronicle gets its own equivalents, shaped by the same `Result`-struct/per-row-transaction
  conventions.
* Grover (or whichever headless-Chrome PDF gem is chosen at Block 1) needs a Chrome/Chromium
  binary at runtime — dev/CI already installs `google-chrome-stable` for Capybara system specs,
  but **PROD does not yet**; this is a new deploy dependency to add to the PROD-readiness doc
  (`Deployment_-_PROD_Readiness.md`) before this feature can actually ship to PROD, not just
  pass CI.

# DEVELOPMENT BLOCKS

## Block 1 — SHIPPED (2026-09-20): Core PDF rendering service + Show page "Download PDF"
* App-agnostic `PdfRenderingService` (Ferrum, not Grover — see Open Questions), A4 page size.
* Show page wires it up: no new permission check, filename = title with spaces → underscores.
* Known deferred issues found in manual testing — see Deferred/Phase 2: a relative-URL body image
  doesn't print, and an unresolved "linebreaks" report.

## Block 2 — SHIPPED (2026-09-20), then revised after manual testing (2026-09-21)
* Rebuilt `BlogExportsController#index` to look like Filter Blog Posts (same Basic/SQL filter UI,
  reusing a new shared `BlogPostFilterable` concern so the filtering logic isn't duplicated
  between `BlogPostsController#filter` and this page — behaviour is byte-for-byte identical to
  Filter Blog Posts for the same params).
* New `pdfs` action (`GET /blog-posts/export/pdfs`) + a `show-panel--actions` Action Panel with
  "Download PDFs" — a plain link carrying the current `request.query_parameters` (same trick
  `filter_sort_link` already uses), so the zip always matches what's on screen. Confirmation
  reuses the global Confirm Dialog for free via `data-turbo-confirm` — the same mechanism the
  existing Delete button uses, zero new JS.
* New app-agnostic `ZipBundlingService` (rubyzip, added as a real dependency — previously only a
  transitive `selenium-webdriver` test-group dependency). Zip filename:
  `BergstromDomain_Chronicle_<ISO date>.zip`. Per-post PDF filenames reuse Block 1's
  title-with-underscores convention, de-duplicated with a numeric suffix on a title collision.
  New `PdfDownloadable` concern (`render_pdf(template:, assigns:)`) factors out the
  render-to-string-then-PDF step shared by Block 1's single-post download and this bulk one.
* **Revision after manual testing (2026-09-21)**: info panel text rewritten to plainly describe
  the two download formats, its buttons (Print/CSV) moved down into the same Action Panel as
  "Download PDFs". **Real bug fixed**: "Download CSV" had been ignoring the filter form entirely
  — `#csv` now calls `compute_filtered_blog_posts` like `#pdfs` does. **"Print / Save as PDF"
  removed entirely** per the user's choice ("not working as expected, happy to remove
  completely") — redundant now that real PDF downloads exist; removed the action/route/view/JS
  controller, kept the global `@media print` CSS rule (confirmed genuinely site-wide, not
  feature-specific).

## Block 3 — SHIPPED (2026-09-21): Import Blog Posts — CSV path
* New `BlogImportsController` (`/blog-posts/import`) mirrors Event_Tracker's `ImportController`
  pattern: upload form + "Download Import Template" link + a results summary (row/error table,
  pluralized "N rows imported, N rows failed" line) rendered back on the same page.
* New `BlogPostImportService`/`BlogPostImportTemplateService`, mirroring `ImportService`'s
  per-row-transaction `Result`-struct pattern. CSV columns: **Title, Category, Subject, Topic,
  Body (Markdown)** — no Author/Created/Published/Classification columns; those are always
  system-controlled (current user, now, Draft, Restricted).
* Imported posts always land as **Draft + Restricted**, the most conservative state — matches
  `ImportService`'s own "always import as the most restricted state" precedent.
* Category matching is case-insensitive against **existing** categories only (unlike
  Event_Tracker's EventType, creating a Blog Category is admin-only) — an unmatched/blank name
  leaves the post uncategorized rather than failing the row, since Category is optional on a
  draft. Template CSV includes one placeholder row per existing category as a reference.
* Left nav gets a new "Import Blog Posts" link alongside "Download Blog Posts". Found and fixed a
  real bug along the way: `Navigable#left_nav_section_for` didn't know about the new
  `blog_imports` controller, which would have rendered a blank left nav on the Import page.
* Deliberately minimal page copy — no Word/Excel guidance or external-tool links yet, since those
  only make sense once Block 4's zip-with-images path exists to receive that content.

## Block 4 — SHIPPED (2026-09-21): Import Blog Posts — Zip package path
* **Redesigned from the original plan after re-reading the spec closely**: the original wording
  said the zip path's "All Metadata (except for author) [is] added manually," unlike the CSV
  path's "All (populated) Metadata are populated" — a deliberate difference. Also, a bespoke
  JSON manifest schema was never realistic, since a real external Word→Markdown converter tool
  produces plain Markdown + images, not app-specific metadata. So Block 4 does NOT use a custom
  manifest: it requires exactly one `.md`/`.markdown` file in the zip (errors clearly if zero or
  more than one), Title is derived from that file's name, Category/Subject/Topic are always left
  blank for the user to fill in after import.
* New `BlogPostZipImportService`, same `Result`-struct shape as the CSV service (reused the exact
  same results-table UI — a zip import is "a CSV import with one virtual row"). Same safety
  defaults: Draft, Restricted, current user as author, same `can_export?` gate — added to the
  SAME `/blog-posts/import` page as a second explained option, not a separate page.
* Images referenced by a relative path in the Markdown (`![alt](images/photo.png)`) are rewritten
  into inline base64 data URIs at import time, matched against the zip's actual file bytes —
  self-contained, and as a side benefit sidesteps the known Block 1 PDF-rendering limitation
  (relative image URLs don't resolve in the isolated PDF render) for all newly-imported content.
* Page copy mentions searching online for a "Word to Markdown" converter tool, deliberately
  without linking a specific one — no real tool was verified, and pointing users at an unvetted
  external site wasn't appropriate.
* **Does NOT cover the admin PROD-migration bulk round-trip** (multiple posts, preserved
  authors/categories/dates) — that remains a separate, still-open Block 5 decision; see Open
  Questions. Given how exploratory the original ask was about that format ("Tar file? XML?
  Other?"), Block 5 is a "revisit if still needed" item, not committed work.

## Block 5 — Deferred decision point
* Only needed if Block 4's format doesn't already cover the admin PROD-migration use case: a
  thin admin-only (`can_administer?`) wrapper to bulk-produce/consume Block 4's zip format.

*(Real `.docx` parsing — the "Ideal"/"Alt 1" Word workflows — is Phase 2, see below, not one of
these blocks.)*

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* All retrofitted call sites verified, old pattern fully removed (no dual implementations left behind)
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
* **Block 1 known issue, confirmed root cause, deferred fix**: an inline body image whose
  Markdown/HTML `src` is a relative ActiveStorage URL (e.g. `/rails/active_storage/blobs/...`)
  does not print — confirmed by inspecting the rendered PDF HTML directly (`grep`-checking image
  `src` values). The PDF template's HTML is fed to `PdfRenderingService` via `document.write` with
  no navigation, so there is no browsing-context origin for a relative URL to resolve against;
  only base64 data URIs work (the header `blog_image`, via the new `blog_image_data_uri` helper,
  and any inline image already stored as base64 — confirmed the normal case for images pasted
  through Quill). Manual testing found this via the "Isaac Newton" seed post's inline "apple tree"
  image (embedded via a relative blob path by the seed script, see
  [[chronicle_posts_test_data]]) — the header image and a real Quill-pasted image both printed
  fine. Fix direction for later: rewrite any relative/ActiveStorage `img src` in the rendered body
  to a base64 data URI at PDF-render time too, the same way the header image already is.
* **Block 1 known issue, not yet diagnosed**: user reported "some issues with linebreaks etc" when
  reviewing the PDF output — not investigated yet, revisit with the user for specifics before
  attempting a fix.
* Real server-side `.docx` parsing (the "Word" import's "Ideal" and "Alt 1" workflows from the
  design discussion) — extracting paragraph/run formatting (bold/italic/headings/lists) via the
  `docx` gem, converting to Markdown, excluding embedded images/tables with a warning per the
  original scope. Deferred until the CSV (Block 3) and zip-package (Block 4) import paths are
  built and proven; Alt 1 (plain-text-only extraction) would be the smaller first cut of this if
  picked up before the fully-formatted "Ideal" version.
* Generalising the core PDF/zip service layer to Event_Tracker itself (not just Cookbook/
  Occasions, which are already in scope) — not requested, but a natural future candidate given
  Event_Tracker's own Import/Export already shares the `Result`-struct/per-row-transaction shape
  this feature is being built around.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* **Resolved:** PDF generation uses headless Chrome, not Prawn — confirmed 2026-09-20. Initially
  agreed as Grover, but investigating it before writing code found it shells out to Node/npm/
  Puppeteer (a real new toolchain this app deliberately has none of) — switched to **Ferrum**
  instead, a pure-Ruby CDP driver using the same Chrome binary already installed for Capybara,
  with the same fidelity benefit and none of the Node dependency. Deploy implication (a Chrome
  binary in PROD) still applies either way, logged under Integration/Migration.
* **Resolved:** the core PDF-rendering/zip-bundling service layer is built app-agnostic from
  Block 1 (not Chronicle-specific), for reuse by Cookbook and likely Occasions — confirmed
  2026-09-20.
* **Resolved:** Word-import sequencing is CSV path (Block 3) → zip-package path (Block 4) →
  real `.docx` parsing deferred to Phase 2 — confirmed 2026-09-20, see the four workflow options
  weighed during planning (Ideal / Alt 1 plain-text / Alt 2 external-tool zip / Alt 3 CSV
  cell-paste) for the reasoning.
* **Still open, revisit at Block 2:** does the "Download Blog Posts" rebuild replace the hidden
  `BlogExportsController` in place, or stay a second page alongside a simpler kept version?
* **Resolved at Block 4's start (2026-09-21):** Block 4's zip-package format does NOT cover the
  admin PROD-migration export/import — it's scoped to the casual single-post "convert my Word doc"
  case (no metadata, current-user-authored). The admin bulk round-trip (multiple posts, preserved
  authors/categories/dates) remains a genuinely open Block 5 decision — not committed work, revisit
  only if the need is still real once Blocks 3/4 have seen real use.
