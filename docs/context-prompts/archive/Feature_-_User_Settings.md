# TASK
* Plan the development to updated the User Settings on BergstromDomain.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* User Settings page to be updated with additional sub pages

* Update left navbar
 * H1: SETTINGS		Icon 'cog'
   * H2: User Settings	New header with icon 'user-cog'
     * User Details 		Rename the link from "User details", use icon 'user-round-cog'
     * Preferences		Create a new page for global "Preferences", use icon 'settings-2'
   * H2: Contact Management	New header with icon 'contact-pen'
     * Contacts		Rename the link from "Contacts Management"
   * H2: App Settings		New header with icon 'monitor-cog'
     * Chronicle Settings	New settings page for the app Chronicle, use icon 'notepad-text'
     * Occasions Settings	New settings page for the app Occasions, use icon 'calendar-range'

* Update "User Details" page
  * Remove the Preference frame and place that in it's own page

* New page, Preferences. Moved from User Settings
  * Start Page: Dropdown list with the options [Home (always first option) followed by each app sorted alphabetically] Current list would be [Home, Chronicle, Occasions]
    * Each app will have it's own start page list
    * The actual startpage when the user logs in will be either Home or if an app is selected, the corresponding app start page
  * Default Visibility - Reword the info text to "Which classifications to show by default when viewing records?"

* New page "Chronicle Settings"
  * Start Page: Dropdown list with the options ["Chronicle" (landing page should always be the default) option), "Browse Blog Posts", "Filter Blog Posts", "My Published Posts", "My Unpublished Posts", "Blog Categories"]
  * Default Classification - Info text to "Which classifications to as default when creating posts?"

* New page "Occasions Settings"
  * Start Page: Dropdown list with the options ["Occasions" (landing page should always be the default) option), "Events By Day", "Events By Week", "Events By Month", "People", "Event Types"]
  * Default Classification - Info text to "Which classifications to as default when creating people and events?"

* Create the file "Feature_-_Style.md" and add step for
  * All left navbar links to be in title case, i.e. all words to be Capitalised for consistency

* Update the file "App_-_TEMPLATE.md and include a step that all apps should have an icon (potential future improvement create an icon from the apps image on the landing page)


---

# SCOPE
* Global 
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase? List known call sites/pages before designing the new one, so this becomes a consolidation, not just an addition. If this feature is about user-facing success/error/info/warning notifications specifically, check first whether it's actually a new `Toastable` trigger (see `app/controllers/concerns/toastable.rb`) rather than a new pattern — most of that space is already covered.
* Both existing and all new apps should be added to the App Settings page (sorted alphabetically)

**Audit findings (2026-09-07):**
* `SettingsController` + `settings/show.html.erb`/`edit.html.erb` is currently one flat page: Profile, a "Preferences" panel (Start Page select + Default Visibility checkboxes), and Change Password.
* `users.start_page` (string column, default `"home"`) is **dead data today** — `after_authentication_url` (`app/controllers/concerns/authentication.rb:43`) never reads it and just falls back to `root_url`; `settings/show.html.erb:66` even hardcodes the displayed value to `"Home"` regardless of what's stored. This feature is the first thing to actually wire login-redirect behaviour up, not just relabel it.
* `users.default_classifications` (string array, checkboxes) only ever filters the People/Events index views. No "default classification used when *creating* a record" concept exists anywhere yet.
* `Chronicle` is already a pure display label over `blog_posts` internals (routes, `AppPermission#app_name`, `Navigable` section, controllers all still say `blog_posts`) — precedent for doing the same with `Occasions`/`event_tracker`.
* `Occasions` doesn't exist in code yet. The only place it's named is the still-unimplemented `Feature_-_App_Landing_Pages.md`, which plans a full `event_tracker` → `occasions` rename plus new `Docket`/`Cookbook`/`Gallery` apps. **Decision: label-only rename here** — Settings pages/nav show "Occasions", but routes/`AppPermission`/`Navigable`/controllers stay `event_tracker`. The technical rename stays with that other feature.
* Person's `new`/`edit` forms and Event's `_form` already have a `classification` select with no `selected:` (falls back to the model's DB default). Blog Post's form has **no** classification field or permitted param at all today.
* Icon check against the installed `lucide-rails` (0.7.4) icon set: `cog`, `user-cog`, `user-round-cog`, `settings-2`, `monitor-cog`, `notepad-text`, `calendar-range` all exist. **`contact-pen` does not** — using `contact-round` instead (confirmed).
* `AppPermission#app_name` already has a per-app enum pattern (`event_tracker`/`blog_posts`/`recipes`/`photo_albums`) — reused as the precedent for the new per-app settings model below.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
* **Login redirect** (new behaviour): on successful sign-in, `after_authentication_url` resolves in priority order: (1) `session[:return_to_after_authenticating]` if present (existing deep-link behaviour, unchanged), else (2) the user's general `start_page` — `"home"` → `root_url`; `"event_tracker"`/`"blog_posts"` → that app's landing page (`event_tracker_url`/`chronicle_url`); else (3) `root_url`. **Built in Block 3** as this two-level (Home vs. app) resolution — consulting `UserAppSetting#start_page` for the finer-grained sub-page is deferred to Blocks 4/5, once those dropdowns (and their specific option-to-route mappings) actually exist to populate it; building that lookup ahead of any UI that could set it would be dead code today.
* **Preferences → Start Page** dropdown options: `Home` (always first), then each app sorted alphabetically by its display name — currently `Chronicle`, `Occasions`.
* **Chronicle/Occasions Settings → Start Page** dropdown: the app's own landing page is always the first/default option, followed by that app's other views, per the doc's per-app option lists.
* **Default Classification** (new, per app): a single-select (not the multi-select "Default Visibility" checkboxes) that pre-fills the `classification` field's `selected:` value on that app's create form. Wires into: Blog Post create form (new field + permitted param, doesn't exist today) for Chronicle; Person/Event create forms (`selected:` added to the existing field) for Occasions.

---

# INTEGRATION / MIGRATION
* New migration: `user_app_settings` table — `user_id` (FK), `app_name` (string, enum matching `AppPermission#app_name`'s values), `start_page` (string, nullable — nil means "app's own landing page"), `default_classification` (string, not null, default `"restricted"` — user must opt in to a more open default; matches `Person`/`Event`/`BlogPost`'s own restricted-by-default posture). Unique index on `[user_id, app_name]`.
* No backfill needed for `start_page` (nil is a valid, meaningful value). `default_classification` needs no backfill either — a DB-level default on the column covers both new and future `UserAppSetting` rows, and rows are created lazily via `find_or_initialize_by` (see `User#app_settings_for`), so no data migration touches existing users.

---

# DATA MODEL
* `UserAppSetting` — `belongs_to :user`; `enum :app_name` reusing `AppPermission`'s values (`event_tracker`, `blog_posts`, `recipes`, `photo_albums`) so the same enum vocabulary is shared across both per-app tables; `start_page` (string, nullable); `default_classification` (string, not null, default `"restricted"`, validated against `Classifiable`'s classification values).
* `User#app_settings_for(app_name)` convenience finder (`find_or_initialize_by` — a Settings sub-page should render even before a row exists for that app).
* Display-name mapping (`"Occasions"` for `event_tracker`, `"Chronicle"` for `blog_posts`) lives in one place (e.g. a small constant/method on `AppPermission` or a presenter) rather than being restated per view — this is what both the App Settings nav list and the Preferences "Start Page" dropdown read from, and it's the seam the future App Landing Pages rename will update in one spot.

---

# DEVELOPMENT BLOCKS

## Block 1 — Data Model & Routes Scaffolding
* `UserAppSetting` model + migration (see DATA MODEL/INTEGRATION above)
* Routes + empty-shell controller actions for the three new pages: Preferences, Chronicle Settings, Occasions Settings (nested under `settings`, e.g. `settings/preferences`, `settings/chronicle`, `settings/occasions`)
* App display-name mapping helper (`Chronicle`/`Occasions`), used by later blocks

## Block 2 — Trim User Details Page
* Remove the "Preferences" panel from `settings/show.html.erb` and `edit.html.erb` (and its params from `SettingsController#settings_params`) — Profile + Change Password + Actions remain
* Existing `spec/features/settings/edit_settings_spec.rb` coverage for the removed panel moves to Block 3

## Block 3 — Preferences Page
* New page: Start Page dropdown (`Home`, `Chronicle`, `Occasions` — alphabetical after Home), Default Visibility (moved as-is, reworded info text: "Which classifications to show by default when viewing records?")
* Wire `after_authentication_url` to actually consult `start_page` (+ the target app's `UserAppSetting#start_page` when an app is chosen) — see BEHAVIOUR SPEC

## Block 4 — Chronicle Settings Page
* New page: Start Page dropdown (Chronicle landing page default, + Browse/Filter/My Published/My Unpublished/Blog Categories), Default Classification (reworded info text: "Which classification to use as default when creating posts?")
* Add a `classification` field to the Blog Post create form (doesn't exist today) + permit it in `BlogPostsController`, pre-filled from this setting
* Extend `after_authentication_url` (Block 3) to consult `UserAppSetting#start_page` for `blog_posts` and resolve to the specific sub-page route, now that this dropdown gives it a real value to read

## Block 5 — Occasions Settings Page
* New page: Start Page dropdown (Occasions landing page default, + Events By Day/Week/Month/People/Event Types), Default Classification (reworded info text: "Which classification to use as default when creating people and events?")
* Pre-fill Person's and Event's create-form `classification` `selected:` from this setting
* Extend `after_authentication_url` (Block 3/4) to consult `UserAppSetting#start_page` for `event_tracker` and resolve to the specific sub-page route

## Block 6 — Left Navbar Restructure
* Restructure the `:settings` section of `_left_nav.html.erb` per the new H1/H2 hierarchy (Settings → User Settings / Contact Management / App Settings), new icons (`user-cog`, `user-round-cog`, `settings-2`, `contact-pen` → `contact-round`, `monitor-cog`, `notepad-text`, `calendar-range`), renamed links ("User Details", "Contacts")
* Link the three new Block 1/3/4/5 pages in; App Settings group sorted alphabetically (`Chronicle`, `Occasions` today — future apps slot in by the same display-name mapping)

## Block 7 — Documentation
* Create `Feature_-_Style.md`: title-case audit of every left-nav link across all sections (existing inconsistencies found: "Events by day/week/month" → "Events By Day/Week/Month", "User details" → "User Details" — the latter already covered by Block 6)
* Update `App_-_TEMPLATE.md`: add a step that every app must define an icon

## Block 8 — Retrofit Existing Usages
* Update/relocate specs for the removed User Details Preferences panel, renamed nav links/testids, changed info-text copy
* Full suite green, coverage not regressed; confirm no other call site read `settings_path`'s old Preferences panel

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
* Full `event_tracker` → `occasions` technical rename (routes, `AppPermission` enum, `Navigable`, controllers) — belongs to `Feature_-_App_Landing_Pages.md`, not here
* `Docket`/`Cookbook`/`Gallery` App Settings sub-pages — not built until those apps exist; `UserAppSetting`'s per-app model is designed so adding them later needs no schema change
* Style audit fixes for nav sections outside Settings (Event Tracker's "Events by day/week/month" casing etc.) — logged in the new `Feature_-_Style.md`, executed there rather than as a side effect of this feature

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~Per-app settings storage model~~ — resolved: new `UserAppSetting` model (2026-09-07)
* ~~"Occasions" naming scope~~ — resolved: label-only rename, technical rename deferred to App Landing Pages (2026-09-07)
* ~~Icon for Contact Management H2~~ — resolved: `contact-round` (2026-09-07)
* ~~Default Classification scope~~ — resolved: store + wire into create forms, including adding a new classification field to Blog Post's form (2026-09-07)
* ~~Should `default_classification` seed to `"restricted"` or stay unset?~~ — resolved: defaults to `"restricted"` (column default, not nullable) — puts the choice to share more broadly in the user's hands rather than assuming it (2026-09-07)
