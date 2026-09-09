# TASK
* Plan the development of a Social Media feature to be added to Occasions (Event Tracker)
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* Many social media platform lets you chose you own user name, great if/when you want to be creative, but makes it harder for your friends to find you. I have usernames associating to my name, my Swedish heritage, my climbing hobbies etc. Many of my friends do the same.
* This feature should allow users to add the usernames to any social media platform. The persons show page should display a list of all stored usernames

---

# SCOPE
* Occasions (Event Tracker)
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase? List known call sites/pages before designing the new one, so this becomes a consolidation, not just an addition. 


---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: standard only — alt text on logo images, keyboard-operable add/remove controls (native elements, no custom widgets). No aria-live announcements for row add/remove (no existing precedent for this in the app).
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
*(Fill in — this replaces a full Data Model / CRUD block for features with no persistent entity. Add a Data Model section back in if the feature does need one, e.g. a notification history.)*
* Social Media Platforms - New model
  * Create - Admin or System Admin should be able to add a social media platform (consistent with EventType/BlogCategory convention — `require_admin`, not `Policy#can_create?`)
  * Read - Guests and users should be able to list and read the social media platform
  * Update - Admin or System Admin should be able to update a social media platform
  * Delete - Admin or System Admin should be able to delete a social media platform (assuming it's not in use)
* Create Social Media Platforms
  * Name - String - Example: facebook
  * URL - String - Example: https://www.facebook.com/
  * Logo - Image - Manually uploaded by the admin (ActiveStorage `has_one_attached`, same pattern as Person/Event/BlogPost images) — not fetched automatically from the platform URL
  * Description - Text - (Optional) - Example: Social media and networking platform
* List Social Media Platforms
  * Add "Social Media Platforms" to left navbar under "Event Types"
  * Show a table with Logo, Name (link to Social Media Platforms), URL (clickable link), Description
* Show and Edit follow normal pages with buttons, created by section etc
* Delete - Confirmation required. Only possible to delete it there is no one using the specific platform
* Add "Social Media Platform Frame" to the person showpage if there are any entries otherwise hide the whole frame
* Edit Person
  * Ability to add a Social Media Platform together with a username
  * Ability to keep adding Social Media Platform together with a username
  * Ability to remove a Social Media Platform
  * A Person may have at most one username per Social Media Platform (uniqueness enforced on person + platform)

---

# INTEGRATION / MIGRATION
* **Existing pattern audit (see SCOPE):** no ad hoc or existing social-media/username handling found anywhere in the codebase (`app/`, `spec/`, `db/`). This is a net-new addition, not a consolidation — the Retrofit Existing Usages block below is N/A.

---

# DEVELOPMENT BLOCKS
*(If this feature turns out to just be a new `Toastable` trigger — see Scope — most of these blocks collapse to "call `toast_created`/`toast_updated`/`toast_deleted` from the relevant controller action" plus a `to_toast_label` method on the model; skip straight to Retrofit Existing Usages.)*

## Core Component — DONE (merged PersonSocialMediaAccount's model layer in here too, since SocialMediaPlatform's own restrict_with_error-on-delete spec needed it to exist)
* `SocialMediaPlatform` model — `name:string`, `url:string`, `description:text` (optional), `logo` (ActiveStorage `has_one_attached`, JPEG/PNG/WebP, 5MB limit — same constraint as `Person#image`). FriendlyId slug on `name` (`:slugged, :history`). `name` unique case-insensitively. Validate `url` is present and a plausible `http(s)://` URL.
* `SocialMediaPlatformsController` — index/show/new/create/edit/update/destroy, `require_admin` before_action on `new`/`create`, `Policy` (`can_update?`/`can_delete?`) on `edit`/`update`/`destroy` — mirrors `EventTypesController`/`BlogCategoriesController` exactly.
* Add `SocialMediaPlatform` to `Policy#app_name_for`'s `event_tracker` case (alongside `Event, EventType, Person`).
* Routes: `resources :social_media_platforms`.
* Index view: table with Logo, Name (links to show), URL (clickable), Description — per BEHAVIOUR SPEC.
* Show/Edit/New views following the `EventType`/`BlogCategory` show/edit/form conventions (`.show-panel`, `resource-form`, `created by`/audit info partial).
* Left nav: new "Social Media Platforms" link under the existing "Event Types" entry in the `:event_tracker` section's Views block; "Create Social Media Platform" action link gated on `current_user&.can_administer?` (matching Event Type's action link, not `Policy#can_create?`).

## Trigger API — DONE
* `PersonSocialMediaAccount` join model — done in Core Component (see above note).
* `Person has_many :person_social_media_accounts, dependent: :destroy` + `accepts_nested_attributes_for :person_social_media_accounts, allow_destroy: true, reject_if: ->(attrs) { attrs["id"].blank? && attrs["social_media_platform_id"].blank? }` — the `id.blank?` guard was a fix mid-build: the originally planned reject_if (blank platform alone) silently dropped legitimate updates to an *existing* row that only sends `id` + `username` (no platform_id resent).
* Added `Person#social_media_platforms_must_be_unique` — a custom in-memory validation. `PersonSocialMediaAccount`'s own DB-scoped uniqueness validator can't see two unsaved sibling rows built together in the same nested-attributes submission (before either is persisted), so a second Red spec was needed to catch that case specifically.
* Known Rails nested-attributes limitation (not fixed, worked around in the spec instead): destroying an existing row and creating a new row for the *same platform* in one single submission fails — the row being destroyed is still physically in the DB when the new row's DB uniqueness check runs. Removing then re-adding the same platform works fine as two separate submissions; documented as a two-step flow rather than adding bookkeeping to suppress it.
* Existing (persisted) rows are removed via a plain `_destroy` checkbox — no JS required for the removal to actually work, it's a normal form submit. Manual testing found the initial visible checkbox+"Remove" text ugly and inconsistent with the app's icon-button convention, so it's now a visually-hidden checkbox toggled by a clickable `icon-button icon-button--danger` label (native `label[for]` click-through, still works with JS disabled). Only "Add Social Media Platform" needs JS — it clones a `<template>` row (`social_media_accounts_controller.js`, new Stimulus controller — no existing pattern fits, `author_shuttle_controller.js` moves whole options between two lists rather than carrying a free-text value per row). A freshly-added, not-yet-saved row's own remove button is a second JS action that just deletes the DOM node (nothing to reach the server for, since it was never persisted).
* JS polish bug: the checkbox toggle initially set the `hidden` attribute to instantly hide a removed row, but `.form-group--inline`'s `display: flex` (an author CSS rule) silently overrides the UA stylesheet's `[hidden] { display: none }`, so nothing visibly happened until the row's own author-set `display` was toggled directly instead (`style.display = "none"`).

## Behaviour / Interaction — DONE
* Person show page: new `.show-panel` section ("Social Media") — a table (Logo/icon, Platform name linked to its show page, Username), rendered only when `@person.person_social_media_accounts.any?` — same conditional-hide convention as the existing Events panel.
* Platform delete: this line turned out to already be satisfied for free by Block 1 — `SocialMediaPlatformsController#destroy` uses the same `turbo_confirm:` convention as every other resource (`EventType`, `BlogCategory`, `Person`, `Event`), and the app's global Confirm Dialog component intercepts `data-turbo-confirm` app-wide (`Turbo.config.forms.confirm`), so there was no separate integration needed. On failed destroy (in use), reuses `toast_error`/redirect-with-alert exactly like `EventTypesController#destroy`.

## Retrofit Existing Usages
* N/A — existing pattern audit (Integration/Migration) found no prior social-media/username handling to consolidate.

## Post-merge polish (manual-testing pass, before PR #65 merged)
* Renamed for clarity/consistency: Person edit's "Social Media" heading → "Social Media Platforms"; "Add Another Platform" → "Add Social Media Platform"; left nav's "Event Type" group → "Reference Data" (it now holds both Event Types and Social Media Platforms).
* Fixed the platform new/edit forms showing "Logo" twice (a visible `<h3>` heading plus a non-sr-only form label — same copy-paste bug in both files).
* Fixed an N+1: `SocialMediaPlatformsController#index` wasn't eager-loading the logo attachment even though the view checks `platform.logo.attached?` per row.
* Found via Bullet while manually testing this feature, fixed as a separate unrelated commit since it long predates this feature: `EventsController#set_event` eager-loaded `people: { image_attachment: :blob }`, but neither `events/show.html.erb` nor `events/edit.html.erb` (the only views it backs) ever render a person's image.

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
*

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~Should Create/Update/Delete of Social Media Platform require Content Creator+ or Admin+?~~ **Resolved:** Admin/System Admin only, matching the `EventType`/`BlogCategory` convention (`require_admin` before_action on `new`/`create`; `Policy#can_update?`/`can_delete?` fall through to `admin_access?` since the model has no `user_id`) — not `Policy#can_create?`'s content_creator allowance.
* ~~How should the Logo image be populated — manual upload, fetch-by-URL, or auto-discovery from the platform's homepage?~~ **Resolved:** manual upload via ActiveStorage, same as Person/Event/BlogPost images. No server-side URL fetching (avoids new SSRF surface / scraping fragility, no library for it in the Gemfile).
* ~~Can a Person have multiple usernames on the same platform?~~ **Resolved:** no — one username per (person, platform), enforced via uniqueness validation.
