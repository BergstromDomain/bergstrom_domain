# TASK
* Plan the development of a Left Navbar Title Case consistency pass, Global — shared across BergstromDomain.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* All left navbar links (`.left-nav-link` text) must be in title case — i.e. every word capitalised, no exceptions for minor words ("and", "by", etc.) — for consistency across sections.
* Left navbar group headers (`.left-nav-h3`) and section headers (`.left-nav-h2`) are already consistently title-cased today and are out of scope; this pass is link text only.

---

# SCOPE
* Global — spans the `:event_tracker`, `:settings`, and `:blog_posts` branches of `app/views/layouts/_left_nav.html.erb`.
* **Existing pattern audit** (as of the User Settings feature's Block 6, which already retitled the `:settings` section's links):

  | Section | Current text | Violation | New text |
  |---|---|---|---|
  | Event Tracker → Views → Events | `Events by day` | `by`/`day` lowercase | `Events By Day` |
  | Event Tracker → Views → Events | `Events by week` | `by`/`week` lowercase | `Events By Week` |
  | Event Tracker → Views → Events | `Events by month` | `by`/`month` lowercase | `Events By Month` |
  | Event Tracker → Import & Export | `Import People and Events` | `and` lowercase | `Import People And Events` |
  | Event Tracker → Import & Export | `Download People and Events` | `and` lowercase | `Download People And Events` |

  Every other link across all three sections (Settings — already fixed; Chronicle/Blog Posts; the rest of Event Tracker) is already correctly title-cased — confirmed by re-reading `_left_nav.html.erb` in full. No other call sites need changing.
* Any apps deliberately excluded for now? Docket/Cookbook/Gallery aren't built yet, so they have no left nav to audit — apply this same title-case rule when their nav sections are first written, rather than retrofitting them here.

---

# DESIGN GUIDELINES
- Text-only change; no new design tokens, components, or JS. N/A for Toast/Stimulus/accessibility guidelines.

---

# BEHAVIOUR SPEC
* No behavioural change — link `href`s, icons, and `data-testid`s are unchanged; only the visible `<span>` text inside five `.left-nav-link` elements changes.

---

# INTEGRATION / MIGRATION
* Call sites to retrofit (all in `app/views/layouts/_left_nav.html.erb`, `:event_tracker` branch):
  * [ ] `Events by day` link text → `Events By Day`
  * [ ] `Events by week` link text → `Events By Week`
  * [ ] `Events by month` link text → `Events By Month`
  * [ ] `Import People and Events` link text → `Import People And Events`
  * [ ] `Download People and Events` link text → `Download People And Events`
* Rollout: single small change, no incremental migration needed.
* Spec fallout to check: any feature spec asserting the old link text via `have_link`/`click_link` (e.g. `spec/features/layouts/left_nav_spec.rb`, and any Event Tracker feature specs that navigate via these links) — grep for the old strings before changing them, update alongside.

---

# DEVELOPMENT BLOCKS

## Title-Case the Event Tracker Links
* Update the 5 link texts listed under Integration/Migration
* Update/rename any spec assertions on the old text
* Full suite green, coverage not regressed

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
* Applying this same title-case rule to Docket/Cookbook/Gallery's left nav sections once those apps are built

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
*
