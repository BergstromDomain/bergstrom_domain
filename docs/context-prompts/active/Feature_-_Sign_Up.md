# TASK
* Plan the development of a Sign Up / User Identity feature — Global (shared across BergstromDomain).
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.
* **Status: mockup/plan only for now** — no implementation until explicitly confirmed.

---

# FEATURE DESCRIPTION
* Registration (`RegistrationsController#create`) already requires and correctly persists `first_name`/`last_name` on `User` — both are real DB columns (`db/structure.sql`), both are `validates ... presence: true` on the model, and the sign-up form (`registrations/new.html.erb`) collects them. **Sign-up itself is correctly wired — this isn't a sign-up bug.**
* The actual gap: several places elsewhere in the app that identify a user to *other* users fall back to `user.email_address` instead of their name, and `User` has no `full_name` method (unlike `Person#full_name`) — the few places that already show a name do it via repeated manual string interpolation (`"#{x.first_name} #{x.last_name}"`) instead of one shared method.
* Goal: add a `User#full_name` accessor (mirroring `Person#full_name`'s existing pattern) and use it everywhere a user's identity is shown to someone else — reserving `email_address` display for the user's own account/login context.

---

# SCOPE
* Global
* **Existing pattern audit** (already done):
  * **Already correct, but duplicated 7 times with no shared method** — all use manual `"#{x.first_name} #{x.last_name}"` interpolation: `app/views/contacts/index.html.erb` (3 spots), `app/views/contacts/_search_results.html.erb`, `app/views/system_admin/users/index.html.erb`, `app/views/system_admin/users/show.html.erb` (2 spots).
  * **Still shows raw email as third-party attribution — the actual gap**: `app/views/people/show.html.erb:145`, `app/views/people/edit.html.erb:127`, `app/views/events/show.html.erb:94` (the "Created by" panels). These are exactly the call sites already flagged for retrofit in the Footer feature's Block 4 (`Feature_-_Footer.md`) — that's what surfaced this gap.
  * **Legitimately email, not a gap**: `app/views/settings/show.html.erb`, `app/views/settings/edit.html.erb` — a user viewing/editing their own account login email, not attribution to a third party. Left unchanged.
  * Sign-in (`sessions/new.html.erb`) and password reset (`passwords/new.html.erb`) forms use "email address" only as the login field label — unrelated to identity display, out of scope.
* Touches once built: `User` model (new `full_name` method), `people/show`, `people/edit`, `events/show`, `events/edit` (Created/Updated By — once Footer Block 4 lands), `contacts/index`, `contacts/_search_results`, `system_admin/users/index`, `system_admin/users/show`.
* Excluded: `settings/show`/`settings/edit`, sign-in/password-reset forms.

---

# DESIGN GUIDELINES
- Mirror `Person#full_name`'s existing pattern (a virtual attribute, not a DB column) — but `User` has no `middle_name` column, so `full_name` is simply `"#{first_name} #{last_name}"`.
- No new design tokens/components — this is a data-consolidation and display change only.

---

# BEHAVIOUR SPEC
* `User#full_name` returns `"#{first_name} #{last_name}"`.
* Anywhere a user's identity is shown to someone other than the account owner, use `full_name` instead of `email_address`.
* Own-account contexts (Settings show/edit) keep showing email — unchanged.

---

# INTEGRATION / MIGRATION
* No schema change — `first_name`/`last_name` already exist and are already required at sign-up.
* Call sites to retrofit:
  * [ ] `people/show.html.erb` — Created By
  * [ ] `people/edit.html.erb` — Created By
  * [ ] `events/show.html.erb` — Created By (`events/edit.html.erb` currently has no admin panel at all — added fresh via the Footer feature's Block 4, using `full_name` from the start rather than needing a second retrofit)
  * [ ] `contacts/index.html.erb` (3 spots)
  * [ ] `contacts/_search_results.html.erb`
  * [ ] `system_admin/users/index.html.erb`
  * [ ] `system_admin/users/show.html.erb` (2 spots)
* Rollout: single pass — pure display change, no behaviour change, low risk.
* **Sequencing with the Footer feature:** Footer's Block 4 (Show-Page Audit Info retrofit) was about to consolidate the Created By/Updated By partial using `user.email_address` (existing behaviour, unchanged) since this feature is plan-only for now. Once `User#full_name` ships here, that partial's one call site becomes a one-line swap rather than a second retrofit pass.

---

# DEVELOPMENT BLOCKS

## User#full_name
Add the method + a model spec (four-section: Happy / Negative / Alternative / Edge — e.g. blank last name, unicode names, Swedish-collation characters already handled by the DB column's collation like `Person`).

## Retrofit Existing Usages
Replace all 7 duplicated-interpolation call sites plus the 3 raw-email call sites with `full_name`. Confirm no regressions in `spec/features/contacts/*`, `spec/features/system_admin/*` (or equivalent).

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
* Consistently pairing `full_name` with the user's `profile_image` thumbnail wherever it's displayed (some call sites already do this ad hoc, e.g. `contacts/index.html.erb`) — worth a pass once `full_name` exists everywhere, but not required to close this feature.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* None currently — this is plan-only per explicit request; no implementation until confirmed.
