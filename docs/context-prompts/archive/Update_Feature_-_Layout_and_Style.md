# TASK
* Plan the development of Layout and Style consistency, Global — shared across BergstromDomain.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
1. Update the layout so that button names and colors are consistent across the site
2. Update the layout so that link names are consistent across the site
3. Update the layout to have consistent headers in the left nav bar across the site
4. Update the layout to have consistent page size 
5. Adjust alignment issues on the top nav bar



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
  * [x] `Events by day` link text → `Events By Day`
  * [x] `Events by week` link text → `Events By Week`
  * [x] `Events by month` link text → `Events By Month`
  * [x] `Import People and Events` link text → `Import People And Events`
  * [x] `Download People and Events` link text → `Download People And Events`
* Rollout: single small change, no incremental migration needed.
* Spec fallout to check: any feature spec asserting the old link text via `have_link`/`click_link` (e.g. `spec/features/layouts/left_nav_spec.rb`, and any Event Tracker feature specs that navigate via these links) — grep for the old strings before changing them, update alongside.

---

# DEVELOPMENT BLOCKS
## Update the layout so that button names and colors are consistent across the site
* I have changed my mind and want to use 'blue' color for all buttons across the site
	Example 'Edit Details' on the 'Settings' page
	This means that the 'Back' buttons will no longer be gray and the 'Delete' buttons will no longer be red
* All button names should be in title case
	I.e. every word capitalised, no exceptions for minor words ("and", "by", etc.) — for consistency across sections
* 'Back to Home', 'Back to Person' etc should be replaced with a simple 'Back'
	Label change only in this block — href/behaviour unchanged. The `return_to` breadcrumb
	mechanism (outlined in the Cookbook app, still in planning stage) is deferred; see
	OPEN QUESTIONS and LEFT NAV STRUCTURE TODOS below. **Confirmed 2026-09-18.**

* Update the CLAUDE.md file as well as the App_-_TEMPLATE.md so that the functionality is clear for future apps


## Update the layout so that link names are consistent across the site
* All left navbar links (`.left-nav-link` text) must be in title case
	I.e. every word capitalised, no exceptions for minor words ("and", "by", etc.) — for consistency across sections.

* Update the CLAUDE.md file as well as the App_-_TEMPLATE.md so that the functionality is clear for future apps


## Update the layout to have consistent headers in the left nav bar across the site
* Left navbar group headers (`.left-nav-h3`) and section headers (`.left-nav-h2`) 

  H1 VIEWS
    H2 [APP NAME]
      * [App name]			Link to landing page
    H2 [APP SPECIFIC HEADER(s)]		Chronicle: 'BLOG POSTS'. Occasion: 'EVENTS', 'PEOPLE'
      * [App Specific Link(s)]
    H2 [MY ITEMS]			Chronicle: 'MY BLOG POSTS'. Occasion: N/A
      * My Published [Items]
      * My Draft [Items]
    H2 REFERENCE DATA
      * [App Specific Reference Data]	Chronicle: 'Blog Post Categories'. Occasion: 'Event Types', 'Social Media Platforms'
  H1 ACTIONS
    H2 NEW
      * [App Specific Link(s)]		Each app can use either Write, Create or Add
					'Write' - Example Blog Post or Recipe
					'Create' - Example Person or Event
					'Add' - Normally for all reference data - Example 'Event Type'
    H2 IMPORT & EXPORT
      * Dowload Recipies		Future improvement (empty link for now)
  H1 DOCUMENTATION	
    H2 HOW TO	
      * User Guide			Future improvement (Use an empty link for now)

* Update the CLAUDE.md file as well as the App_-_TEMPLATE.md so that the functionality is clear for future apps


## Update the layout to have consistent page size 
* Use full size for 'normal' data, both for New, Show and Edit
  * Example New Blog Post
* Use half size for 'reference' data, both for New, Show and Edit
  * Example Event Types

* Update the CLAUDE.md file as well as the App_-_TEMPLATE.md so that the functionality is clear for future apps


## Adjust alignment issues on the top nav bar
* Change the dropdowns so that the values are left aligned with the header
* @tmp/screenshots/DropDownAlignment.png shows how the values are to the left of the actual dropdown


---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* All retrofitted call sites verified, old pattern fully removed (no dual implementations left behind)
* Confirmed with me before moving to the next block

---

# LEFT NAV STRUCTURE TODOS (raised during Cookbook planning, 2026-09-17)
*(Separate from this doc's own title-case scope — logged here only because the Cookbook
plan (`docs/context-prompts/active/App_-_Cookbook.md`) explicitly pointed here. Retitle
this whole doc, or split these into their own feature doc, once Cookbook's left nav design
is actually confirmed and this list needs to move from "future TODO" to "in progress.")*
* [x] Chronicle: rename "Unpublished" → "Draft" in left-nav link text (`filter_blog_posts_path(..., published: "draft")` link currently reads "My Unpublished Posts"). **Done in Block 3, 2026-09-18** — now "My Draft Posts". Note: the Chronicle Settings page's "default landing page" dropdown (`app/views/settings/chronicle_settings.html.erb`) still has an option literally named "My Unpublished Posts" (value `my_unpublished_posts`) — left untouched since it's a settings dropdown, not left-nav, and its value string may be persisted in `UserAppSetting` rows; flagged as a possible follow-up, not fixed here.
* [x] Occasions + Chronicle: rename the "CATEGORIES" `left-nav-h2` section header → "REFERENCE DATA". **Done in Block 3, 2026-09-18** — Occasion already had it; Chronicle's `.left-nav-h3` header (Occasion's structural equivalent) renamed. Link text under it ("Blog Categories") left unchanged — not renamed to "Blog Post Categories" as one doc annotation suggested, to avoid mismatching the destination page's own `<h1>Blog Categories</h1>` title.
* [x] Occasions + Chronicle: add a "NEW" `left-nav-h3` subgroup under the ACTIONS section (grouping the "Create X" / "Add a Y" links that currently sit loose under ACTIONS). **Done in Block 3, 2026-09-18.** Chronicle's admin-only "Deleted Posts" link doesn't fit "New" (it's not a create action) — left loose directly under ACTIONS, ungrouped.
* [x] Occasions + Chronicle: move the Import/Export links to a subsection under ACTIONS (currently their own top-level area). **Done in Block 3, 2026-09-18** for Occasions (only app with this feature wired into the left nav). Chronicle has no Import/Export left-nav entry at all yet — confirmed deliberately absent via existing spec coverage ("hidden pending redesign"), not added here.
* [x] Occasions + Chronicle: add a new "DOCUMENTATION" `left-nav-h2` section with a "HOW TO" `left-nav-h3` subgroup (holding a "User Guide" link). **Done in Block 3, 2026-09-18.**
* [ ] Occasions + Chronicle: adopt the `return_to` query-param breadcrumb pattern (Cookbook's Design Question-4 answer) on their own Read/Show pages' Back button — Browse/Filter/My-X list links append `?return_to=<path>`, Back uses that param (validated as a relative path only) instead of always returning to a fixed page. **Still deferred** — see Block 1's "Confirmed 2026-09-18" note; waits for Cookbook's left-nav design.

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
* Applying this same title-case rule to Docket/Cookbook/Gallery's left nav sections once those apps are built

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~Block 1's 'Back' simplification conflicted with the LEFT NAV STRUCTURE TODOS note that
  the `return_to` breadcrumb pattern should wait for Cookbook's left-nav design to be
  confirmed.~~ **Resolved 2026-09-18:** Block 1 does the label rename only ('Back to Home' →
  'Back', href unchanged); the `return_to` mechanism itself stays deferred, tracked in LEFT
  NAV STRUCTURE TODOS.
* ~~Whether 'all buttons blue' should recolor the existing four `.btn-*` classes in place, or
  collapse them into a single class and update ~34 view call sites.~~ **Resolved
  2026-09-18:** recolor in place — `.btn-primary`/`.btn-secondary`/`.btn-danger` repoint their
  color declarations at the existing `--color-primary` blue (already used by
  `.btn-primary-action`). No view-file changes.
