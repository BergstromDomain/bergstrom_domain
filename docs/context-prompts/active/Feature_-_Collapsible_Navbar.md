# TASK
* Plan a left-nav space-management feature — collapsible/expandable sections and/or a show/hide
  toggle for the main frame — to be added to Global — shared across BergstromDomain, once enough
  apps exist that the sidebar's item count becomes a real problem.
* Raised during Cookbook planning (`docs/context-prompts/active/App_-_Cookbook.md`, Design
  Question-1/2) and explicitly deferred out of Cookbook's scope — Cookbook ships with the left
  nav's existing `overflow-y: auto` scroll behaviour, no new code.
* **Confirmation gate:** before starting a new development block, summarise what you know so far
  (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open
  design questions before progressing. Do not skip ahead to implementation on an unconfirmed
  block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor),
  the four-section spec structure (Happy / Negative / Alternative / Edge), the
  `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop →
  rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* Two distinct interactions, shipped together as one feature (confirmed 2026-09-19):
  1. **Collapsible/expandable `left-nav-h2` sections** — `chevron-up` collapses, `chevron-down`
     expands. Each H2 group (e.g. "Chronicle >> Views", "Chronicle >> Actions", "Occasions >>
     Views") toggles independently — collapsing one never affects any other.
  2. **Show/hide the whole left nav** — `chevrons-left` hides it down to a thin restore-only
     strip, `chevrons-right` (rendered in that strip) restores it.
* **Persistence: per user *and* session (confirmed 2026-09-19).** Backed by the existing `Session`
  model (`app/models/session.rb` — a real DB-backed row per login, not just a cookie; see
  `Authentication#start_new_session_for`/`#terminate_session`), not a new per-user table — a fresh
  `Session` row already gets created on every login and destroyed on logout, so state stored on it
  is naturally per-user, resets to defaults on the next login, and needs no separate cleanup.
* **Defaults for each new login:** left nav visible, every H2 section expanded.
* **Whole-nav visibility rule:** hiding the nav is a per-app/per-page-context action, not a
  standing preference — navigating to a different app or info/settings page makes it visible
  again automatically (otherwise the user could strand themselves with no way to navigate). It
  only stays hidden across multiple page loads *within* the same app/section (e.g. browsing
  several Blog Posts pages while hidden keeps it hidden).
* **Section-collapse persistence:** each H2 section's collapsed/expanded state persists across
  navigation for the rest of the session (until the user expands it again, or logs out).
* **Confirmed 2026-09-20 — hidden-nav treatment:** rather than removing the nav entirely, `.left-nav`
  shrinks to a thin strip containing only the `chevrons-right` restore control — always reachable,
  minimal footprint.

---

# SCOPE
* Global — spans `app/views/layouts/_left_nav.html.erb` and every app's section within it
  (Event Tracker, Chronicle/Blog Posts, Cookbook, and future apps).
* **Existing pattern audit** (as of 2026-09-17): `.left-nav` already has `overflow-y: auto` (see
  `app/assets/stylesheets/application.css`) — a long nav already scrolls today rather than
  overflowing the viewport. This feature is about reducing scroll depth / reclaiming screen
  width, not fixing a broken/overflowing layout.
* Which apps/pages does this touch once built: every page with the left nav rendered (i.e. every
  authenticated app page) — this is a layout-level change, not a single controller/view.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components rather than introducing new ones — flag if this
  feature genuinely needs a new token/pattern.
- Reuse existing JS conventions (e.g. `dropdown_controller.js`'s Stimulus toggle shape) rather
  than a one-off script.
- Accessibility: keyboard operability and `aria-expanded`/`aria-hidden` state for both the
  section-collapse toggles and the whole-nav show/hide toggle need explicit design, not an
  afterthought.

---

# BEHAVIOUR SPEC
* **Whole-nav toggle**: `chevrons-left` button at the top of the expanded nav; clicking it shrinks
  `.left-nav` to a thin strip containing only a `chevrons-right` restore button. Instant (CSS
  class toggle via Stimulus), backed by a background persistence call — no page reload, no
  visible loading state.
* **Section toggle**: each `left-nav-h2` gets a `chevron-up`/`chevron-down` button; clicking
  collapses/expands that H2's own `h3`/link children only. Same instant-toggle-plus-background-
  persist mechanics as the whole-nav toggle.
* **Persistence mechanics**: two small PATCH endpoints update columns on `Current.session`
  (whole-nav visibility; add/remove one key from the collapsed-sections list). On the *next* full
  page load, the layout/nav partial reads those same columns to render the correct initial state
  server-side — no flash-of-wrong-state, and it works even with JS disabled (state still applies
  on the next request, just without the instant client-side toggle).
* **Auto-restore rule**: implemented as a side effect of `Navigable#set_left_nav` (already runs on
  every request) — if the computed `@left_nav_section` differs from what's stored on the session,
  the nav is forced visible again and the stored section is updated. No per-link opt-in needed.
* **Accessibility**: both toggle types use a real `<button>` with `aria-expanded` reflecting
  current state; the H2 section's `h3`/link children get `aria-hidden`/removed from tab order
  while collapsed (mirroring `dropdown_controller.js`'s show/hide, not a new pattern).
* Edge cases: guest/unauthenticated pages (no `Current.session`) always render fully
  expanded/visible, no toggle controls, no persistence attempted; a section with zero `h3` groups
  never happens today (every rendered H2 has at least one), so no "collapse an empty section" case
  exists yet.

---

# INTEGRATION / MIGRATION
* Call sites: `app/views/layouts/_left_nav.html.erb` (all three `@left_nav_section` branches —
  `event_tracker`, `settings`, `blog_posts` — each needs the same toggle markup added
  independently, since they're not currently deduplicated into a shared partial/loop; that
  dedup is out of scope here unless it turns out to be required to implement this cleanly),
  `app/views/layouts/application.html.erb` (`@show_left_nav` today is hardcoded `true` in
  `Navigable#set_left_nav` — becomes session-driven), `app/controllers/concerns/navigable.rb`,
  `application.css`'s `.left-nav*` rules.
* Rollout approach: additive migration on `sessions` (new columns, sensible defaults) — no data
  migration needed, existing sessions just get the defaults (nav visible, nothing collapsed) on
  their next request.

---

# DEVELOPMENT BLOCKS

## Block 1 — Session-backed persistence layer (no UI yet) ✅ Done 2026-09-20
* Migration: `sessions` gains `left_nav_visible` (boolean, default `true`, null: false),
  `left_nav_section` (string, nullable), `collapsed_nav_sections` (string array, default `[]`,
  null: false) — array column has precedent in this schema (`default_classifications`).
* `Session` model: helper methods for reading/toggling visibility and per-key section collapse,
  plus the "sync section, force-visible-if-changed" method `Navigable#set_left_nav` calls.
* `Navigable#set_left_nav` updated to compute `@show_left_nav` from `Current.session` (falling
  back to `true` for guests/no session) and run the auto-restore-on-section-change side effect.
* New `LeftNavsController` with two endpoints: `PATCH /left_nav/toggle_visibility`,
  `PATCH /left_nav/toggle_section` (param: `key`). No view wiring yet — provable via model/request
  specs alone.
* **Bug found and fixed while building this:** `Navigable#set_left_nav` can't just read
  `Current.session` — several controllers (`EventTypesController`, `BlogCategoriesController`,
  `SocialMediaPlatformsController`, `BlogPostsController`) `allow_unauthenticated_access` on some
  actions and resume the session themselves via their own `resume_session_if_present`
  before_action, declared *after* `include Navigable` in the class body. Callback registration
  order meant `set_left_nav` ran first and saw no session at all for a signed-in user hitting one
  of those actions. Fixed by having `Navigable` resume the session itself
  (`Current.session ||= find_session_by_cookie`, same as `Authentication#resume_session`) instead
  of trusting another before_action to have run first — covered by
  `spec/requests/left_nav_spec.rb`.
* Verified: `spec/models/session_spec.rb`, `spec/requests/left_nav_spec.rb` (the auto-restore
  behavior), `spec/requests/left_navs_spec.rb` (the two endpoints) all green; full suite still
  green (801 non-feature + 968 feature examples); RuboCop/Brakeman/bundler-audit clean.

## Block 2 — Whole-nav show/hide UI ✅ Done 2026-09-20
* `left_nav_controller.js` (Stimulus): instant CSS toggle + background `fetch` PATCH to persist,
  same pattern as `blog_post_editor_controller.js`'s fetch+CSRF-header call.
* `chevrons-left` button in the expanded nav; `.left-nav` CSS gets a collapsed/thin-strip state
  containing only a `chevrons-right` restore button.
* Server-rendered initial state from `Current.session.left_nav_visible?`.
* Feature specs: toggle hides/restores the nav; state survives a second page load in the same
  app/section; navigating to a different app/section auto-restores it.
* **Plan correction found while building this:** Block 1 wired `@show_left_nav` (whether
  `_left_nav.html.erb` renders at all — also drives the footer's fixed indent, see
  `FooterHelper#footer_class`) directly from `Current.session.left_nav_visible?`. That's wrong for
  the now-confirmed "thin strip, always reachable" design — a fully-not-rendered nav would remove
  the restore button entirely. Fixed: `@show_left_nav` is unconditionally `true` again (its
  original, structural meaning — "does this page have a nav section at all"); the collapsed vs.
  expanded state is a separate CSS class (`.site-shell--nav-collapsed`) driven by
  `Current.session.left_nav_visible?` directly in the view, toggled instantly by
  `left_nav_controller.js` and kept in sync with the footer's indent via CSS in one place.
* **Also found:** the toggle buttons don't navigate anywhere themselves, so a user could click a
  nav link immediately after toggling, aborting the in-flight persistence `fetch` on page unload.
  Fixed with `keepalive: true` on the fetch (survives navigation) plus a
  `data-left-nav-syncing` flag tests can wait on before triggering a reload — same purpose as
  `confirm_dialog_controller.js`'s `data-ready` flag.
* **Guests get no toggle controls at all** — they have no `Session` to persist to, and the
  buttons would otherwise redirect them to sign in unexpectedly. Not explicitly speced, but a
  necessary consequence of "per user and session" persistence.
* Verified: `spec/features/layouts/left_nav_visibility_spec.rb` (new), `spec/features/layouts/left_nav_spec.rb`
  (existing, unaffected by the new wrapper markup), full suite green (801 non-feature + 972
  feature examples); RuboCop/Brakeman/bundler-audit/importmap-audit clean.
* **Note on flakiness observed while testing:** intermittent `sign_in_and_settle` failures showed
  up in this spec during development. Stress-testing the pre-existing, already-shipped
  `confirm_dialog_spec.rb` the same way reproduced the *same* class of failures (Escape/backdrop
  click tests failing 5/5 in one run) — this is pre-existing Selenium/headless-Chrome flakiness in
  this environment, not something this feature introduced. A single full-suite run stayed green.

## Block 3 — Per-section collapse/expand UI
* Same Stimulus controller (or a second action on it) wires `chevron-up`/`chevron-down` on every
  `left-nav-h2` across all three `_left_nav.html.erb` branches.
* Collapsing one H2 only affects its own `h3`/link children — verified independent of sibling
  sections (including across different apps, e.g. "Chronicle >> Views" vs "Occasions >> Views").
* Server-rendered initial collapsed/expanded state per section from
  `Current.session.collapsed_nav_sections`.
* Feature specs: independent toggling; state survives navigation within the session; resets to
  all-expanded on next login (covered by a model-level Session spec, not a full login-cycle
  feature spec).

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
* This entire feature is itself deferred — Cookbook (and every app before it) ships without it,
  relying on the left nav's existing scroll behaviour.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning — all resolved as of
2026-09-20, see Feature Description/Behaviour Spec for the decisions.)*
* ~~Persistence scope~~ — resolved: per user and session, backed by the `Session` model.
* ~~Default state~~ — resolved: nav visible, all sections expanded, on every new login.
* ~~Where does the restore control live once the nav is hidden~~ — resolved: `.left-nav` shrinks
  to a thin strip containing only the `chevrons-right` restore button.
* ~~One feature or two~~ — resolved: shipped together (two related toggles, three blocks).
* ~~Is there an actual usability problem yet, or is this pre-emptive~~ — moot: the user chose to
  build it now regardless.

Ready to start Block 1.
