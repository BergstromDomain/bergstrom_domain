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

## Block 1 — Core PDF rendering service + Show page "Download PDF"
* App-agnostic PDF-from-HTML rendering service (Grover), A4 page size.
* Show page wires it up: no new permission check, filename = title with spaces → underscores.
* Settles the PDF-gem choice and Gemfile/Chrome-binary footprint for every later block that
  needs a PDF.

## Block 2 — "Download Blog Posts" page rebuild
* Filter UI reusing `BlogPostFilter`, an Action Panel (`show-panel--actions`) with "Download
  PDFs", Confirm Dialog gate showing the filtered count, zip-of-PDFs response (new zip gem,
  built as the app-agnostic zip-bundling service from the cross-cutting behaviour above).

## Block 3 — Import Blog Posts: CSV path
* Chronicle equivalents of `ImportService`/`ImportTemplateService`/`Result`, per-row transaction
  import, CSV template download, results summary rendered to the importing user.

## Block 4 — Import Blog Posts: Zip package path
* Manifest + image files zip format (Markdown per post), a linked external Word→Markdown+images
  converter tool referenced from the page, import creates posts + re-attaches images.
* Revisit former Open Questions #2–#4 (admin PROD-migration export, whether it needs
  authors/comments, whether a separate admin block is still needed) once this format exists —
  likely resolves to "reuse this same format," not a bespoke one.

## Block 2 — SHIPPED (2026-09-20), then revised after manual testing (2026-09-21)
* Manual-testing findings on `/blog-posts/export`: the info panel text was rewritten (explains the
  two download formats plainly, matches actual behaviour), its buttons moved down into the same
  Action Panel as "Download PDFs" (info panel is now text-only).
* **Real bug fixed**: "Download CSV" ignored the filter form entirely (always exported everything
  visible, regardless of what was selected) — `BlogExportsController#csv` now calls
  `compute_filtered_blog_posts` like `#pdfs` already did, and the link carries
  `request.query_parameters` the same way.
* **"Print / Save as PDF" removed entirely**, per the user's explicit choice ("not working as
  expected, happy to remove completely") now that both Block 1 (per-post PDF) and this block's
  zip-of-PDFs make the old browser-print workaround redundant. Removed: the `print` action/route,
  `app/views/blog_exports/print.html.erb`, `print_controller.js` (confirmed unused elsewhere first
  via grep). The global `@media print` CSS rule (hides `.top-nav`/`.left-nav`/`.site-footer`/
  `.print-hide` on any page print) was NOT removed — confirmed it's genuine site-wide print
  styling, not specific to the removed feature.
* Original Block 2 summary below, still accurate for what shipped initially:
* Rebuilt `BlogExportsController#index` to look like Filter Blog Posts (same Basic/SQL filter UI,
  reusing a new shared `BlogPostFilterable` concern so the filtering logic isn't duplicated
  between `BlogPostsController#filter` and this page — behaviour is byte-for-byte identical to
  Filter Blog Posts for the same params).
* Existing "Print / Save as PDF" / "Download CSV" panel kept exactly as it was (unfiltered, all
  visible posts) — deliberately NOT folded into the new filtered flow, to avoid silently changing
  established behaviour beyond what was asked.
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
* **Resolved:** PDF generation uses a headless-Chrome gem (Grover), not Prawn — confirmed
  2026-09-20. Deploy implication logged under Integration/Migration.
* **Resolved:** the core PDF-rendering/zip-bundling service layer is built app-agnostic from
  Block 1 (not Chronicle-specific), for reuse by Cookbook and likely Occasions — confirmed
  2026-09-20.
* **Resolved:** Word-import sequencing is CSV path (Block 3) → zip-package path (Block 4) →
  real `.docx` parsing deferred to Phase 2 — confirmed 2026-09-20, see the four workflow options
  weighed during planning (Ideal / Alt 1 plain-text / Alt 2 external-tool zip / Alt 3 CSV
  cell-paste) for the reasoning.
* **Still open, revisit at Block 2:** does the "Download Blog Posts" rebuild replace the hidden
  `BlogExportsController` in place, or stay a second page alongside a simpler kept version?
* **Still open, revisit at Block 4:** does the admin PROD-migration export/import (originally a
  separate "[XXX] format, Admins only" ask) end up fully covered by Block 4's zip-package
  format, or does it still need its own thin wrapper (Block 5) — and if so, does the round-trip
  need to carry authors/co-authors/likes/comments, or just post content + category + images?
