# TASK
* Plan the development of a Toast feature, built as a **global, reusable component** across BergstromDomain. Initial wiring targets Event Tracker and Chronicle, alongside an audit-and-retrofit pass on any existing flash-like messaging elsewhere in the app.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
The toast should be displayed on Create, Update and Delete for all items in both the Event Tracker and the Chronicle apps.
  * What triggers it?
    * Create [Person | Event | Event-Type | Post | Category] — success and failure (validation)
    * Update [Person | Event | Event-Type | Post | Category] — success and failure (validation)
    * Delete [Person | Event | Event-Type | Post | Category] — success and failure. Chronicle's
      `BlogPost` delete additionally fires a companion Info toast (it's a soft-delete with a
      restore window — see `blog_posts_controller.rb#destroy` — unlike Person/Event/Event-Type/
      Category, which have no restore mechanism and so get Success/Error only).
    * Publish (Chronicle) — success and failure (the controller already branches both today)
    * Unpublish (Chronicle) — success only (no failure path exists today; `unpublish` uses `update!`)
    * **Draft-mode indicator (Chronicle)** — not an action outcome at all: a persistent, state-driven
      Warning toast replacing the current `draft-badge` span next to the title on the post show
      page (`app/views/blog_posts/show.html.erb:14-21`). See Behaviour Spec for how this differs
      mechanically from every other toast in this list.
  * What it shows/does — visual style modeled on Netflix's account-change banners (full-width colour bar, icon + single line of text, no separate header row):
    * Success — Create/Update/Delete/Publish/Unpublish: Icon + "[Entity name] has been successfully created/updated/deleted/published/unpublished" (e.g. "John Smith has been successfully updated"), using the record's specific identifying name in all cases, not a generic entity-type label.
    * Info — fired **alongside** the Success toast, two distinct cases:
      * Update, when the record's identifying name/title changes: Icon + "[Old Name] has been
        updated to [New Name]" (e.g. "Alex Smith has been updated to Alexandra Anderson"). Does
        **not** fire when an Update leaves the identifying field unchanged — Success only then.
      * Delete, Chronicle `BlogPost` only: Icon + "The post can be restored by Admin for 30 days."
        Replaces the current combined message in `blog_posts_controller.rb#destroy`
        ("Blog post deleted. An admin can restore it within 30 days.") with a Success + Info pair,
        consistent with the rest of this spec. Doesn't apply to Person/Event/Event-Type/Category
        deletes — no restore window exists for those.
    * Warning — Draft-mode indicator only (see above): Icon + "This post is still in Draft mode."
    * Failure — Create/Update/Delete/Publish: Icon + the specific validation/constraint text
      (`errors.full_messages.to_sentence`), matching the convention already used at all 90 existing
      `notice:`/`alert:` call sites — not a generic message.
  * How the user dismisses it / how it resolves on its own
    * Flash-based toasts (Success/Info/Error above): auto-dismiss after 3 seconds, and manually dismissible.
    * The Draft-mode Warning toast: **non-dismissible** — no auto-dismiss and no manual close
      control. Stays visible for as long as the post remains unpublished, i.e. until the post is
      published. Resolved: dismissing it would just have it reappear on the next page load of the
      same draft, so a close control has no real effect and isn't worth building.

---

# SCOPE
* **Global** — build once as a shared component, then retrofit any existing flash-like messaging across BergstromDomain (not just Event Tracker/Chronicle).
* **Existing pattern audit — done.** The whole app currently uses Rails' built-in two-bucket
  flash (`notice:`/`alert:`), rendered by a single loop in
  `app/views/layouts/application.html.erb:25-26`:
  ```erb
  <% flash.each do |type, message| %>
    <div class="flash <%= type %>" data-testid="flash-<%= type %>"><%= message %></div>
  <% end %>
  ```
  90 call sites across 9 controllers use it today (full list under Integration/Migration below).
  Message wording is currently inconsistent — some generic ("Event type created."), some specific
  ("#{@event_type.name} muted.") — the retrofit should resolve to the specific-name pattern
  throughout, not preserve the inconsistency.
* Apps/pages touched: Event Tracker, Chronicle, plus every call site listed under
  Integration/Migration below.
* Apps deliberately excluded for now: none identified.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones. **Flag:** the current design system only has an off-white/terracotta palette plus a blue primary token — dedicated Success (Green), Error (Red), and Warning (Orange) tokens likely don't exist yet and will need to be added deliberately, not improvised per-component. Warning now needs a real, finished style (not a placeholder) since the Draft-mode indicator gives it a live trigger from day one.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: `aria-live="polite"` region so toasts are announced without stealing focus; dismiss control reachable by keyboard (Tab + Enter/Space); focus stays wherever it already was rather than jumping to the toast.
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; toasts are visible to whoever triggers the action, so likely N/A — confirm no exceptions (e.g. does a Visitor ever trigger one of these actions?).

---

# BEHAVIOUR SPEC

Two distinct trigger mechanisms, not one:

1. **Flash-based** (Create, Update, Delete, Publish, Unpublish) — fired server-side, carried across
   one redirect via standard Rails flash, rendered once, then gone. This is what all 90 existing
   call sites already do today; the toast component replaces their rendering, not their trigger
   plumbing.
2. **State-based** (Draft-mode Warning only) — not tied to an action or a redirect at all. Rendered
   directly from `@blog_post.published?` on every render of the post's show page, for as long as
   that's true. Needs its own partial/helper called from the view, separate from the flash
   pipeline — see Trigger API block.

* Trigger(s):
  * Create, Update, Delete — success and failure outcomes (flash-based).
  * Update — additionally fires a companion Info toast when the identifying name/title changes; no
    Info toast when other fields change (flash-based).
  * Delete, Chronicle `BlogPost` only — additionally fires a companion Info toast ("The post can
    be restored by Admin for 30 days."), since it's a soft-delete with a restore window. Other
    entities' deletes (Person/Event/Event-Type/Category) are hard deletes — Success/Error only,
    no Info (flash-based).
  * Publish — success and failure, per the branching already in `blog_posts_controller.rb:121-128`
    (flash-based).
  * Unpublish — success only; no failure path exists today (flash-based).
  * Draft-mode Warning — viewing an unpublished post's show page (state-based, not flash-based).
* Variants/types: **Success (Green)**, **Info (Blue)**, **Error (Red)**, and **Warning (Orange)**
  all have defined triggers for v1 — none remain deferred.
* Visual style: modeled on the Netflix account-banner reference — full-width coloured bar, icon on the left, single line of message text (no separate header row).
* Content: Icon + message, single row (see Feature Description for exact wording per variant).
* Placement: Directly under the top navbar, spanning the **full width of the main content frame** (excludes the left navbar), with small horizontal padding on each side.
* Timing:
  * Flash-based toasts: auto-dismiss after 3 seconds, and manually dismissible.
  * Draft-mode Warning: non-dismissible — no auto-dismiss, no manual close, persists until the
    post is published.
* Stacking: Success above Info/Warning, small fixed gap (~8px), top to bottom by "what happened"
  then "detail". Three realistic simultaneous cases to design for, not just the Update pair:
  * Creating a post (Draft by default) redirects to its own show page — the one-time Success toast
    and the persistent Draft-mode Warning both render together on that first view.
  * Unpublishing a post redirects to its own show page too — same stacking of a one-time Success
    toast alongside the now-(re)appearing persistent Warning.
  * Deleting a Chronicle post redirects away from it (to `chronicle_path`) — Success + Info stack
    once, on that redirect target, with no Warning involved (the post no longer renders at all).
* Persistence across navigation: flash-based toasts survive one redirect (standard Rails flash)
  and are then gone; the Draft-mode Warning is re-derived from record state on every render, so it
  reappears on every subsequent visit to that post's show page, not just once.
* Edge cases: triggered during a Turbo Stream update; triggered twice in quick succession;
  triggered with no user signed in (shouldn't apply — these are authenticated actions, confirm);
  Success + Warning stacking on Create/Unpublish (see Stacking above).

---

# INTEGRATION / MIGRATION
* Call sites to retrofit onto the new pattern. **Correction:** the original audit list below was
  built from a truncated grep and only surfaced 9 of the actual 17 controllers using
  `notice:`/`alert:` — corrected during Block 2. `to_toast_label` and the `Toastable` concern
  (`toast_created`/`toast_updated`/`toast_deleted`/`toast_validation_error`) are the generic
  mechanism now available to every remaining controller below:
  * [x] `app/views/layouts/application.html.erb:25-26` — the flash-render loop itself, replaced by
    the new toast component (Block 1)
  * [x] `app/controllers/people_controller.rb` — create/update/destroy now use `Toastable` and the
    specific-name pattern, including the Update-rename Info companion (Block 2, proof-of-concept)
  * [x] `app/views/blog_posts/show.html.erb:14-21` — the `draft-badge` span, replaced by the
    **state-based** Draft-mode Warning toast, non-dismissible (Block 2, proof-of-concept)
  * [ ] `app/controllers/events_controller.rb` — create/update/destroy/mute/unmute
  * [ ] `app/controllers/event_types_controller.rb` — create/update/destroy/mute/unmute,
    authorisation alerts
  * [ ] `app/controllers/blog_categories_controller.rb` — create/update/destroy, authorisation
    alerts
  * [ ] `app/controllers/blog_posts_controller.rb` — publish/unpublish/restore; `destroy`'s
    combined message ("Blog post deleted. An admin can restore it within 30 days.") splits into a
    Success + Info pair via `toast_deleted(@blog_post, info: "...")`
  * [ ] `app/controllers/likes_controller.rb` — authorisation/invalid-reaction alerts
  * [ ] `app/controllers/comments_controller.rb` — create/destroy, authorisation alerts
  * [ ] `app/controllers/contacts_controller.rb` — contact request notices/alerts
  * [ ] `app/controllers/import_controller.rb` — validation alerts
  * [ ] `app/controllers/export_controller.rb` — export notices/alerts
  * [ ] `app/controllers/registrations_controller.rb` — sign-up notices/alerts
  * [ ] `app/controllers/settings_controller.rb` — settings update notices/alerts
  * [ ] `app/controllers/passwords_controller.rb` — reset-flow notices/alerts
  * [ ] `app/controllers/sessions_controller.rb` — auth alerts
  * [ ] `app/controllers/blog_exports_controller.rb` — authorisation alerts
  * [ ] `app/controllers/system_admin/base_controller.rb` — authorisation alerts
  * [ ] `app/controllers/system_admin/users_controller.rb` — approve/reject/suspend/reactivate
    notices
* Rollout approach: Global — audit and retrofit existing flash-like messages everywhere, not just Event Tracker/Chronicle.
* Anything that must keep working unchanged during the transition? **Resolved, revised from the
  original plan:** rather than renaming all 90 call sites' flash keys, `ToastHelper#toast_variant_for`
  maps the existing `notice`/`alert` keys onto success/error styling, so untouched controllers
  render correctly today with zero changes. This was discovered to matter more than expected — 19
  existing feature specs assert directly on `data-testid="flash-notice"`/`"flash-alert"`, which
  would otherwise have broken across the board. Retrofitting a controller now means switching it
  onto the `Toastable` concern for the *specific-name* message pattern and any Info companion, not
  a mandatory key rename — `notice:`/`alert:` remain valid, just visually mapped rather than
  canonical going forward.

---

# DEVELOPMENT BLOCKS

## Core Component — done
* `app/views/shared/_toast.html.erb` / `_toasts.html.erb`, `app/helpers/toast_helper.rb`,
  `app/javascript/controllers/toast_controller.js`. Four style variants, all wired to real design
  tokens (`--color-success`/`--color-info`/`--color-warning`/`--color-danger`, which — corrected
  during Block 1 — already existed; no new tokens were needed).
* Flash-key vocabulary decision, revised from the original plan: `notice`/`alert` stay valid,
  mapped visually onto success/error; `success`/`info`/`warning`/`error` are canonical for new
  code. See Integration/Migration for why (19 specs assert on the old testids).

## Trigger API — done (proof-of-concept on one controller + one view; full sweep is Retrofit)
* Flash-based: `Toastable` concern (`app/controllers/concerns/toastable.rb`, included in
  `ApplicationController`) — `toast_created(record)`, `toast_updated(record, previous_label:)`,
  `toast_deleted(record, info: nil)`, `toast_validation_error(record)`. Depends on a
  `to_toast_label` method on the model (added to Person, Event, EventType, BlogPost,
  BlogCategory — full_name/title/name respectively). Proven end-to-end on
  `PeopleController#create/update/destroy`.
* State-based: the `shared/_toast` partial takes a `testid:` override (added in Block 2, alongside
  the flash-key default) so it can be called directly from a view outside the flash pipeline.
  Proven end-to-end on `blog_posts/show.html.erb`'s Draft-mode Warning, replacing the old
  `draft-badge` span (also removed its now-dead `.draft-badge` CSS).
* **Note surfaced while wiring Person's create/update failure path:** Person's forms already show
  a well-tested inline `.form-errors` block on validation failure — `toast_validation_error` adds
  an Error toast *alongside* that, not instead of it. Both are live now, which is arguably
  belt-and-suspenders for every remaining controller too. Flag for confirmation before the
  Retrofit block treats this as the standard pattern everywhere, rather than assuming it.

## Behaviour / Interaction
* Show/dismiss logic per Behaviour Spec: 3s auto-timer + manual close for flash-based toasts;
  non-dismissible, no timer, for the state-based Draft-mode Warning
* Stacking (Success above Info/Warning, ~8px gap) per Behaviour Spec

## Retrofit Existing Usages
* Replace each call site logged under Integration/Migration
* Confirm no regressions in affected specs

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
* Person's create/update failure now shows both an Error toast and the pre-existing inline
  `.form-errors` box, saying the same thing twice. Keep both (toast for attention, inline for
  per-field detail) as the standard pattern for the Retrofit block, or drop the Error toast for
  actions that already render inline validation errors and reserve it for failures that don't
  (e.g. the restrict-with-error Delete case on EventType/BlogCategory)?