# TASK
* Plan the development of a Footer feature to be added to be shared across BergstromDomain.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* Three problems to resolve
  1) As an end-user, when I notice a different behavior, I want to be able to see if there has been any updates since I last used the system.
  * This can be resolved by adding "Deployed date: 1-Jan-2026" as a footer
  * **Decision:** a pre-build step generates a small build-info file (version + git SHA + build date), checked/copied into the app before it runs. No deployment pipeline exists yet (Docker/Kamal in the repo is unused so far), so this file is the one mechanism that works regardless of how/where it's eventually deployed.
  2) Future state when end-users can report bugs, I want to know on which version the issue was found (especially if/when I dont resolve it right away
  * A version in the footer would be better than relying on the deployment date
  * **Decision:** a manual `VERSION` file at the repo root, `Major.Minor.Patch`, bumped by hand as part of a release PR — no existing versioning mechanism (no VERSION file, no git tags) and no automated release tooling today, so this matches the project's current manual, single-dev PR workflow. New app = major, new feature = minor, bug fix = patch, per the original suggestion. (Automating the bump from commit type is logged under Deferred / Phase 2.)
  3) During development I want even more details of what I'm testing against
     * Adding the commit hash might be the best way
     * **Decision:** included in the same build-info file as the deploy date/version (see #1) — a single generation step covers all three.

* Suggested approach, each page should display a footer indicating which version of the software is used
* **Version:** v1.2.3 (left aligned) | **Date: ** 1-Jan-2026 (right aligned)
* **Environment:** [DEV | TEST] (do not display this row for PROD) (left aligned) | **Git:** c520c88

---

# SCOPE
* Global 
* **Existing pattern audit** (findings):
  * A footer shell already exists and is already rendered on every page: `app/views/layouts/_footer.html.erb` (currently just a `<footer>` with a "Full implementation in Post #19" comment), wired into `app/views/layouts/application.html.erb`. CSS (`app/assets/stylesheets/layouts/footer.css`) already defines `.site-footer` using existing tokens (`--color-footer-bg`, `--color-footer-text`, `--footer-height`). This feature fills in that stub — no new footer partial or layout wiring needed.
  * No version/build-metadata mechanism exists anywhere (no VERSION file, no CHANGELOG, no git tags, no `APP_VERSION`/`GIT_SHA`/`REVISION` references) — this part is a genuinely new pattern, not a consolidation.
  * "Created by {email} at {date}" already exists on show pages as a `show-panel--admin` block, but it's **duplicated across 3 call sites** with an inconsistency: `app/views/people/show.html.erb:143-147`, `app/views/people/edit.html.erb:125-127`, `app/views/events/show.html.erb:92-94` — but **not** `app/views/events/edit.html.erb`, which has no admin panel at all. This is the actual "ad hoc/inconsistent existing version" the audit is meant to catch — see the Retrofit block below.
  * This is not a `Toastable` concern — no success/error/info/warning notification involved.
* Add footer to all pages
* For show pages add
  **Created By:** [User Name] | **Date:** "2-Jan-2026" | **Updated By:** [User Name] | **Date:** "2-Jan-2026"
  * **Decision:** no `updater_id`/updater tracking exists in the schema today (`people`/`events` only have a creator `user_id`). Add a real migration (`updater_id` on both tables, set on every update) rather than faking it with `updated_at` alone — see INTEGRATION / MIGRATION below. Consolidate the 3+1 existing/missing admin-panel call sites into one shared partial while extending it, rather than duplicating the new Updated By markup a 4th time.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
*(This feature does need a small Data Model addition — see INTEGRATION / MIGRATION — alongside the behaviour below.)*
* Placement: Bottom of the page, full width for pages without left navbar, for pages with left navbar, full with of the main frame
* Global footer row 1 (top): **Environment:** DEV | TEST (left, omitted entirely when `Rails.env.production?`) | **Git:** short SHA (right) — environment badge maps directly to `Rails.env` (no separate `APP_ENVIRONMENT` var; no real staging deployment exists yet to warrant one).
* Global footer row 2 (bottom): **Version:** vX.Y.Z (left) | **Deployed Date:** deploy date (right) — both sourced from the build-info file generated at build time.
* All four labels (Environment/Git/Version/Deployed Date) render bold via `.site-footer__label` (`--font-weight-semibold`), matching the existing label-styling convention elsewhere (e.g. `.show-meta-cell__label`); values themselves are not bold.
* Local dev fallback: when no build-info file has been generated (e.g. plain `bin/dev`), fall back to reading `VERSION` directly and shelling out to git locally for the SHA/date — `.git` is genuinely present in a dev checkout, unlike a built artifact.
* On pages with the left navbar, the footer's left-aligned content is offset by the nav's width plus the main frame's own inner padding (`.site-footer--indented`), so it lines up with actual page content rather than starting under the nav column.
* Show-page audit row: **Created By** / **Date** always shown (existing behaviour, unchanged). **Updated By** / **Date** shown only once a record has actually been edited (i.e. `updater_id` present) — don't show a redundant "Updated by" row on a never-edited record.

---

# INTEGRATION / MIGRATION
* Migration: add nullable `updater_id` (references `users`) to `people` and `events`. Nullable because existing records have never been "updated" by this definition.
* Set `updater_id = Current.user.id` in the relevant `update` controller actions (`PeopleController#update`, `EventsController#update`) — creator (`user_id`) assignment on create is unaffected.
* Build-info generation: a rake task (or small script) run before the app boots in a built/deployed context, writing version + short git SHA + build date to a small checked-file (exact filename/format decided during that block's own TDD cycle). Not part of the request cycle — read once at boot/render time.

---

# DEVELOPMENT BLOCKS
*(Renamed from the generic template headers — this feature has no "trigger" concept, the footer is unconditionally rendered on every page already.)*

## Build & Version Metadata — DONE
`VERSION` file (`1.0.0`, to be bumped starting from the first PROD deployment) + `lib/tasks/build_info.rake` (`build_info:generate`) writing `config/build_info.yml` (gitignored) + `BuildInfoService` reader with independent per-field fallback to `VERSION`/local git. Full four-section spec (`spec/services/build_info_service_spec.rb`).

## Global Footer Rendering — DONE
`FooterHelper` (`footer_version`/`footer_deploy_date`/`footer_git_sha`/`footer_environment_label`/`show_footer_environment_row?`/`footer_class`) + `app/views/layouts/_footer.html.erb` filled in, two rows (Environment/Git on top, Version/Deployed Date below — reordered per feedback), bold labels, `.site-footer--indented` offset on pages with the left nav. Covered by a helper spec, a view spec, and a request spec.
**Gotcha hit:** `app/assets/stylesheets/layouts/footer.css` is not actually served — Propshaft doesn't process `@import`, so `app/assets/stylesheets/application.css` is the single hand-maintained bundle each modular file's content must be manually pasted into. Both are now kept in sync; any future CSS change must edit `application.css` (the live copy) or it silently has no effect.

## Show-Page Audit Info (Created By / Updated By) — DONE
Migration adds nullable `updater_id` to `people`/`events` (no DB-level FK, matching the existing `user_id` convention). New `Auditable` concern (`belongs_to :updater, class_name: "User", optional: true`) included in both models, parallel to `Classifiable`'s `belongs_to :user` for the creator. `PeopleController#update`/`EventsController#update` set `@person.updater`/`@event.updater = current_user` before saving. Covered via feature-spec assertions in the existing `edit_person_spec.rb`/`edit_event_spec.rb` (matches this codebase's convention of testing controller-update effects at the feature-spec level, not a dedicated request spec) — including the admin-edits-someone-else's-record case, which distinguishes creator from updater. View rendering (showing Updated By only when present) is still pending — that's Block 4 (Retrofit), next.

## Retrofit Existing Usages — DONE
New shared partial `app/views/shared/_audit_info.html.erb` (locals: `record`, `testid`) renders Created By (always) and Updated By (only when `record.updater.present?`) as a left/right-aligned flex row — `.show-panel--admin` restyled to `display:flex; justify-content:space-between`, bold labels via a shared `.show-admin__label, .site-footer__label { font-weight: var(--font-weight-semibold); }` rule, matching the footer's visual language per earlier feedback. Applied to `people/show`, `people/edit`, `events/show`, and `events/edit` (previously had no admin panel at all — now consistent with the other three). Per the `Feature_-_Sign_Up.md` sequencing decision, still displays `email_address`, not a name — that's a one-line swap once `User#full_name` ships from that feature. Old duplicated markup fully removed from all 3 original call sites, no dual implementations left behind.

**All four Footer feature blocks are now DONE.**

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
* Automating the VERSION bump from commit type (feat → minor, fix → patch) instead of a manual edit — revisit if manual bumps prove error-prone.
* A separate `APP_ENVIRONMENT` var decoupled from `Rails.env` — only worth it once a real staging deployment exists distinct from local dev/test.
* Deployment itself (Docker/Kamal) is out of scope for this feature — the build-info file is designed to not depend on how/where that eventually happens.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~Version numbering mechanism~~ — RESOLVED: manual `VERSION` file.
* ~~Deploy date / git SHA capture, given `.git` isn't guaranteed present in a built artifact~~ — RESOLVED: pre-build build-info file.
* ~~What DEV/TEST/PROD should reflect, given no deployment exists yet~~ — RESOLVED: maps directly to `Rails.env`.
* ~~Updated By with no updater tracking in the schema~~ — RESOLVED: add real `updater_id` migration, consolidate the existing duplicated admin-panel views while extending them.
* Exact build-info file name/format (e.g. `REVISION` vs `config/build_info.yml`) — left to the Build & Version Metadata block's own TDD cycle rather than pre-deciding here.
