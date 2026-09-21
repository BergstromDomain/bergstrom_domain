# TASK
* Plan the development of a User Guide feature to be added to 'Global — shared across BergstromDomain'.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* A User Guide to be added under Info >> User Guide and be visible to Visitors and Users
* Left nav bar should allow the user/visitor to navigate through the User Guide
* Each app should have a link to the corresponding app section in the User Guide
* Several Design Questions, DQ(s) which I want your inputs on
  * DQ-1: Should the User Guide be limited to a 'Visitor' version for guests? 
    * → **Claude's recommendation: no separate Visitor edition.** The stub route is already guest-accessible. One unified document per app section, with inline "Content Creator and above" callouts for role-gated features (same spirit as DQ-6's own "probably little value" note), is less to maintain than a second parallel document and avoids the two ever drifting out of sync.
  * DQ-2: Should the User Guide be one page or several ones (core + one for each app)?
    * → **Claude's recommendation: several — a core landing page plus one page per app**, mirroring how `chronicle_path`/`event_tracker_path` are already separate hub pages. This is also the only way to satisfy "each app should have a link to the corresponding section" cleanly, and it composes with DQ-3's answer below (separate DB records, not separate static views).
  * DQ-3: Should the User Guide be of 'Blog Post' type, i.e.allowing Admin(s) to edit or should it be system generated?
    * → **Claude's recommendation: a new, lean DB-backed model (working name `GuidePage`) — not literally `BlogPost`, not static ERB.** Reusing `BlogPost` directly would drag in authorship/co-authors/Likes/Comments/publish-workflow that don't apply here. But static ERB templates give DQ-4 (a required review/update step) nothing to hook into — no `updated_at`, no "needs review" flag, nothing a check can query. A small model (`title`, `app_section` enum, `body` markdown) admin/content-creator-editable, reusing `BlogPost.render_markdown`'s Markdown→sanitized-HTML pipeline (possibly worth extracting into a shared concern rather than duplicating — flagged under Open Questions below), gives both editability and something DQ-4 can check against.
  * DQ-4: How to add 'User Guide Review/Update' as a required step before pushing code to GitHub?
    * → **Claude's recommendation: start with process, not code.** A checklist line (PR description / commit convention) is cheap and matches this repo's existing style of enforcing conventions via the commit-msg hook rather than heavier CI logic. A CI check that maps changed app files → required Guide-page touches would need a brittle heuristic (which files belong to which section); defer that to Phase 2 and only build it if the process-only version proves insufficient in practice.
  * DQ-5: Should a separate Admin Guide be created as a separate page with restriced access?
    * → **Claude's recommendation: yes, but as a natural extension of DQ-2/DQ-3's model, not a bespoke feature** — just another `GuidePage` `app_section` value (e.g. `:admin`) gated the same way other admin-only content already is (`current_user&.can_administer?`), rather than a separate table/controller. Content itself (lorem ipsum) can wait for Phase 2 same as everything else.
  * DQ-6: Besides the Visitor and Admin handled as separate questions, should there be a User Guide for each persona?
	* If the signed in user is not a 'Content Creator' limit the User Guide to only showing what this user can do
        * There is probably little value in developing this
    * → **Claude's recommendation: agree, drop this.** DQ-1's inline role callouts already cover "what can I actually do" more cheaply than N full parallel documents would.
* This feature is mainly about the structure for the User Guide
  * I'm aware that there will be many iterations of the design before the first deployment
  * The actual data in the User Guide does not have to be created until I'm ready to deploy the first version to PROD, until then 'lorem ipum' is fine
  * Future improvement will include how-to videos for each feature


---

# SCOPE
* Global 
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase? List known call sites/pages before designing the new one, so this becomes a consolidation, not just an addition. If this feature is about user-facing success/error/info/warning notifications specifically, check first whether it's actually a new `Toastable` trigger (see `app/controllers/concerns/toastable.rb`) rather than a new pattern — most of that space is already covered.
  * **Not a blank slate — found an existing stub already wired up:**
    * `PagesController#user_guide` (`app/controllers/pages_controller.rb`) + `get "user_guide", to: "pages#user_guide", as: :user_guide` already exist, `allow_unauthenticated_access` already includes it (guests can already reach it).
    * `app/views/pages/user_guide.html.erb` is a static one-line stub: "User guide coming in a future post."
    * The left nav's `Documentation (h2) > How To (h3) > User Guide` link (exactly the shape CLAUDE.md's Left Nav Structure section documents) is **already duplicated verbatim in both the `:event_tracker` and `:blog_posts` branches** of `_left_nav.html.erb`, both pointing at the same single `user_guide_path` — i.e. the "Info" section this doc asks for already exists under the name "Documentation," it's just empty.
  * **Real bug found, becomes load-bearing for this feature**: `Navigable#left_nav_section_for` (`app/controllers/concerns/navigable.rb`) routes controller `"pages"` to `:event_tracker` for every action except `"chronicle"` — so `/user_guide` currently always renders the **Event_Tracker** left nav, even when reached from a Chronicle page. Harmless today (the page is a dead stub), but breaks the moment the Guide becomes multi-page/per-app, since each Guide page needs to render under *its own* app's nav section, not always Event_Tracker's.
  * No `:recipes`/`:photo_albums` left-nav section or controller exists yet at all (Cookbook is paused, Photo_Album is unstarted) — "each app should have a link to the corresponding section" can only be wired for Event_Tracker/Chronicle today; the other two get a placeholder/lorem-ipsum section with no nav entry to link from yet.


---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC


---

# INTEGRATION / MIGRATION

---

# DEVELOPMENT BLOCKS
*(If this feature turns out to just be a new `Toastable` trigger — see Scope — most of these blocks collapse to "call `toast_created`/`toast_updated`/`toast_deleted` from the relevant controller action" plus a `to_toast_label` method on the model; skip straight to Retrofit Existing Usages.)*

*(Draft block breakdown below — confirmed by the user 2026-09-21; Core Component now shipped, see status below.)*

## Core Component — DONE (2026-09-21)
* `GuidePage` model + migration: `title`, `slug` (friendly_id), `app_section` enum
  (`:core`, `:event_tracker`, `:blog_posts`, `:recipes`, `:photo_albums`, `:admin`,
  one row per value enforced by a uniqueness validation + unique index), `body`
  (markdown text).
* Admin-gated CRUD (`GuidePagesController`, mirrors `BlogCategoriesController`
  exactly: `allow_unauthenticated_access` on index/show, `require_admin` before
  new/create, `Policy#can_update?/can_delete?` on edit/update/destroy — falls
  through to `admin_access?` automatically since `GuidePage` has no `user_id`
  and isn't in `Policy#app_name_for`, so **no `Policy` changes were needed**).
  Content-creators are *not* guide editors — same admin-only bar as
  `BlogCategory`/`EventType`, a judgment call since the doc never specified this;
  flag if content-creator editing turns out to be wanted later.
* **Page sizing judgment call**: used `resource-form--wide`/full-width-unwrapped
  Show (the "normal data" convention), not the narrow Reference-Data width —
  `body` is prose content closer to `BlogPost`'s body than to `BlogCategory`'s
  short description field. Not explicitly confirmed beforehand; flagging here.
* Markdown render pipeline: **extracted** `BlogPost.render_markdown`/`#rendered_body`
  into a new `MarkdownRenderable` concern (`app/models/concerns/markdown_renderable.rb`),
  now included by both `BlogPost` and `GuidePage` — resolves the "shared vs.
  duplicated" open question below in favor of shared. `BlogPost`'s own
  `RENDERED_BODY_ALLOWED_TAGS`/`_ATTRIBUTES` sanitizer constants were left in
  place (untouched call sites); `GuidePage` got its own copy of the same
  constant values rather than sharing the constant itself, so the two can
  diverge later without coupling.
* **No `Classifiable`** — resolves the other open question below (guide pages
  are public/admin-editable only, no restricted/contacts state).
* Full four-section spec coverage (model + 5 feature spec files mirroring
  `BlogCategory`'s), full suite green (1921 examples, 1 pre-existing unrelated
  flaky failure — `create_blog_post_spec.rb`'s co-author shuttle test, fails
  only under full-suite Selenium load, passes in isolation, not touched by
  this block), coverage 96.27% (COVERAGE=1), rubocop/brakeman/bundler-audit
  all clean.
* Not yet done: left-nav wiring, the `/user_guide` landing page retrofit, and
  the `Navigable` nav-context bug fix — all explicitly deferred to Behaviour /
  Interaction below.

## Trigger API
* N/A — not a `Toastable`-style trigger feature; this block is a placeholder only
  if some future block needs one (e.g. a "Guide updated" notification), not
  expected for the initial build.

## Behaviour / Interaction
* Fix the `Navigable#left_nav_section_for` bug found in Scope: a `GuidePage`'s
  own `app_section` needs to drive which left-nav section renders around it,
  not the current `"pages"` controller → `:event_tracker` fallback.
* Per-app left nav links (already present under Documentation > How To in both
  `:event_tracker` and `:blog_posts`) get re-pointed from the single shared
  `user_guide_path` to that section's own `GuidePage`.
* Core/landing guide page lists links to each app's section.

## Retrofit Existing Usages
* Replace each call site logged under Integration/Migration
* Confirm no regressions in affected specs
* Remove the static stub view/action once `GuidePage`-backed pages replace it.

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
* Real Guide content (lorem ipsum until ready for PROD, per FEATURE DESCRIPTION).
* How-to videos per feature.
* DQ-4's CI-enforced review-gate (start with a process-only checklist instead).
* DQ-5's actual Admin Guide content (the `app_section: :admin` plumbing itself
  can ship in Core Component if cheap, but real content waits).
* Recipes/Photo_Album Guide sections have no app of their own to link from yet
  (both unstarted) — their `GuidePage` rows can exist but stay unlinked from
  any left nav until those apps themselves exist.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~Should `BlogPost.render_markdown`'s Markdown/sanitizer pipeline be
  extracted into a shared concern for `GuidePage` to reuse, or duplicated?~~
  **Resolved in Core Component: extracted into `MarkdownRenderable`.**
* ~~Does `GuidePage` need `Classifiable`?~~ **Resolved in Core Component: no.**
* Exact left-nav-context-preservation mechanism for the "core" landing page
  (not tied to any one app_section) — does visiting the core Guide page from
  a Chronicle page keep the Chronicle nav, or fall back to something generic?
  Needs a concrete answer before Behaviour/Interaction block starts.
* Should content-creators (not just admins) be able to edit Guide pages?
  Core Component shipped admin-only (matching `BlogCategory`/`EventType`'s
  Reference-Data bar) as a judgment call, not an explicit decision — revisit
  if that turns out to be too restrictive.
