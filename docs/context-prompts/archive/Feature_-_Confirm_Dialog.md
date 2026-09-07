# TASK
* Plan the development of a Confirm Dialog feature — a styled, on-brand replacement for the
  browser's native `window.confirm()` popup, which today shows as an ugly, unstyled
  "localhost:3000 says" browser-chrome dialog (see `tmp/screenshots/DeletePerson.png`) wherever
  Turbo's `data-turbo-confirm` is used. Global — shared across BergstromDomain.
* **Confirmation gate:** before starting a new development block, summarise what you know so far
  (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open
  design questions before progressing. Do not skip ahead to implementation on an unconfirmed
  block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor),
  the four-section spec structure (Happy / Negative / Alternative / Edge), the
  `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop →
  rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.
* **Relationship to Toasts:** this is a distinct feature from the just-shipped Toast component,
  not an extension of it. A toast is a non-blocking, after-the-fact notification; this is a
  blocking yes/no gate that must resolve *before* the underlying request even fires. They solve
  different problems and don't share a trigger mechanism — but this feature should reuse the same
  design tokens (danger/terracotta palette, `.btn-danger`/`.btn-secondary`, spacing/radius scale)
  for visual consistency with Toasts and the rest of the app.

---

# FEATURE DESCRIPTION
* What triggers it: any element with `data-turbo-confirm="..."` — currently 10 call sites across
  9 views (full list under Integration/Migration). Today Turbo calls the browser's native
  `window.confirm(message)` for these; there is no in-app dialog UI at all yet.
* What it shows/does: a centered, styled modal — message text, a primary action button (labelled
  per context, e.g. "Delete", "Suspend", "Reject" — not just a generic "OK") and a "Cancel"
  button, dimmed backdrop behind it.
* How the user dismisses it / how it resolves: clicking the primary action resolves the gate as
  confirmed and the original request proceeds; clicking Cancel (or, tbd — see Open Questions,
  pressing Escape / clicking the backdrop) resolves it as cancelled and nothing happens, exactly
  matching today's native-confirm behavior (Cancel/Escape → no request sent).

---

# SCOPE
* Global (usable by any app) — this replaces Turbo's confirm behavior app-wide, not per-view.
* **Existing pattern audit — done.** All 10 current call sites, full grep for
  `turbo_confirm`/`turbo-confirm` across `app/views/`:
  * `app/views/people/show.html.erb:134` — "Delete #{full_name}? This cannot be undone."
  * `app/views/events/show.html.erb:85` — "Delete #{title}? This cannot be undone."
  * `app/views/event_types/show.html.erb:55` — "Delete #{name}? This cannot be undone."
  * `app/views/blog_categories/show.html.erb:55` — "Delete #{name}? This cannot be undone."
  * `app/views/blog_posts/show.html.erb:173` — "Delete "#{title}"? This can be restored by an
    admin within 30 days."
  * `app/views/comments/_comment.html.erb:60` — "Delete this comment?"
  * `app/views/contacts/index.html.erb:59` — "Are you sure you want to remove #{name} from your
    contacts?"
  * `app/views/settings/show.html.erb:198` — "This will suspend your account. Are you sure?"
  * `app/views/system_admin/users/show.html.erb:117` — "Reject and permanently delete this
    registration?"
  * `app/views/system_admin/users/show.html.erb:131` — "Suspend #{name}?"
* No existing modal/dialog pattern exists anywhere in the codebase to consolidate — this is a new
  UI primitive, not a consolidation (unlike Toasts, which replaced an existing ad hoc mechanism).
* Apps/pages touched: all 9 views above, plus any future `data-turbo-confirm` usage automatically
  (the fix is a global Turbo config override, not a per-view change).
* Apps deliberately excluded for now: none.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (`--color-danger`/`--color-danger-dark`, `.btn-danger`/`.btn-secondary`, `--radius-md`, `--space-*`) rather than introducing new ones — flag if this feature genuinely needs a new token.
- Visually distinct from a Toast (this is a modal overlay with a dimmed backdrop, centered on screen; a Toast is a full-width banner under the top nav) — don't let the two patterns blur together despite sharing a palette.
- Reuse existing JS conventions (a Stimulus controller) rather than a one-off script.
- Accessibility: focus should move into the dialog on open and be trapped there until it closes; Escape should behave like Cancel (see Open Questions); the dialog needs an accessible name/description (`aria-labelledby`/`aria-describedby` or the native `<dialog>` element's built-in semantics) and focus should return to the triggering button on close.
- Consistent with existing Authentication/Authorisation and Data Classification: N/A — this is presentation-only, doesn't change who can trigger a confirmable action.

---

# BEHAVIOUR SPEC
* Trigger(s): any `data-turbo-confirm="message"` attribute on a Turbo-driven link or
  `button_to` form (existing Rails/Turbo API — call sites don't need to change at all, only the
  rendering of the confirmation itself).
* Mechanism: Turbo (turbo-rails 2.0.23 confirmed installed) supports overriding the confirm step
  via `Turbo.config.forms.confirm = async (message, element, submitter) => { ... }` — Turbo
  `await`s the return value and only proceeds if it's truthy. This is the one integration point;
  no changes needed to any of the 10 existing call sites' `data-turbo-confirm` strings themselves.
* Variants/types: none needed — unlike Toasts, this isn't a multi-variant notification system,
  just one dialog shape. (Its primary button could pick up `--color-danger` vs. a neutral color
  depending on whether the action is destructive — see Open Questions.)
* Content: message text (from the existing `data-turbo-confirm` string, unchanged), a primary
  button, a Cancel button.
* Placement: centered overlay, dimmed backdrop behind it, above all other page content.
* Timing: no auto-dismiss (it must wait for a real yes/no answer) — closes only on an explicit
  choice.
* Stacking: N/A — a confirm gate blocks the page; only one can be open at a time by construction
  (nothing else can be interacted with, let alone trigger a second one).
* Persistence across navigation: N/A — it's resolved (or cancelled) before any navigation happens;
  it never survives a page transition.
* Edge cases: rapid double-click on the trigger while the dialog is already open; triggering
  Cancel then immediately re-triggering the same action; a `data-turbo-confirm` string containing
  HTML-unsafe characters (must render as plain text, not be interpreted as markup); keyboard-only
  operation (Tab should stay trapped inside the dialog, Enter should activate the focused button).

---

# INTEGRATION / MIGRATION
* Call sites to retrofit — **none need code changes.** All 10 sites already use the standard
  `data-turbo-confirm`/`turbo_confirm:` API; overriding `Turbo.config.forms.confirm` globally is
  the entire migration. This is closer to Toasts' Block 1 (build the component) than its Block 4
  (touch every call site) — there is no per-call-site retrofit block for this feature.
* Rollout approach: big-bang — the override applies globally the moment it's registered
  (typically in `app/javascript/application.js` or a dedicated Stimulus/initializer file), so all
  9 views get the new dialog simultaneously.
* Testing implication worth flagging: today's feature specs pass under the `rack_test` driver
  (non-JS), which doesn't execute JavaScript at all — `data-turbo-confirm` is silently a no-op
  there today, and Rack::Test-driven `button_to` submits go straight through. That won't change:
  the new dialog only renders under a real browser (`js: true` specs), exactly like the native
  confirm it replaces. No existing non-JS spec should need to change because of this feature.
* Anything that must keep working unchanged: the existing `data-turbo-confirm="..."` message
  strings and the underlying request behavior (Cancel/Escape → no request sent, confirm → request
  proceeds exactly as it does today) — only the visual presentation changes.

---

# DEVELOPMENT BLOCKS

## Core Component — DONE
Native `<dialog>` (`app/views/shared/_confirm_dialog.html.erb`, rendered once globally in the
layout right after the footer) + `confirm_dialog_controller.js`: `open(message)` returns a
Promise; `confirm()`/`cancel()` settle it; the native `cancel` event (Escape) and a
backdrop click (`event.target === dialogTarget`, since the `<dialog>` itself is sized to the full
viewport with the visible card as an inner child) both settle as cancelled; focus returns to the
trigger on close; a guard (`if (this.dialogTarget.open) return Promise.resolve(false)`) no-ops a
redundant `open()` call. Styled with existing tokens only (`--space-*`, `--radius-md`,
`--shadow-md`, `--color-surface`) — no new tokens needed. Covered by a view spec (four sections)
proving the static markup; no controller-behavior spec yet at this stage since nothing was wired
to a real trigger (see Trigger API).

## Trigger API — DONE
`Turbo.config.forms.confirm = (message) => this.open(message)` registered in the controller's
own `connect()` — zero changes to any of the 10 existing call sites. First full end-to-end
`js: true` feature spec added (`spec/features/shared/confirm_dialog_spec.rb`, Delete Person flow)
covering all four sections: Confirm proceeds, Cancel blocks it, Escape/backdrop-click both cancel,
HTML-unsafe message renders as plain text.
**Gotcha hit:** `Selenium::WebDriver::Element#displayed?` (which Capybara's default `visible: true`
relies on, including inside `have_text`) doesn't reliably recognize a native `<dialog>` shown via
`showModal()` — confirmed the `open` attribute is genuinely `true` in the live DOM while
Capybara still reported it as not found. Fixed by asserting on the `[open]` attribute directly
with `visible: :all` throughout the spec, rather than the default visibility check.

## Behaviour / Interaction — DONE
Turned out to be mostly verification, not new code — native `showModal()` already provides the
Tab focus-trap and Enter-activates-focused-button behavior for free, and Block 1's `_settle`
logic already handled focus-return/reset-for-reopen correctly. Added specs for: Tab stays trapped
+ Enter activates the focused button; a genuine second click can't reach the trigger once the
modal makes the page inert (verified directly, rather than via a synthetic same-tick double
`.click()`, which was found to actually confuse Turbo's own form-submission bookkeeping in a way
no real user interaction can reproduce); re-opening cleanly after a Cancel.
**Gotcha hit:** the sign-in form (`app/views/sessions/new.html.erb`) is a hard-navigation form
(`data: { turbo: false }`), so each sign-in in these specs is a genuine full page reload; under
load this occasionally took longer than the existing flaky-sign-in retry helper's 3s wait.
Bumped to 8s, which measurably helped. Residual flakiness beyond that matches the same
pre-existing "JS driver session isolation issue" already accepted elsewhere in this suite (e.g.
`show_settings_spec.rb:215`'s `xit`) — a single clean full-suite run hit it once in 1536+
examples, consistent with that existing baseline, not a regression from this feature.

## Manual Verification — DONE
Exercised in a real browser via `bin/dev`. First pass surfaced four styling issues (see
screenshot feedback below), all fixed and re-confirmed as looking correct:
1. Message now splits into a question row and a detail row at the first sentence break (a small
   regex in `open()`, e.g. `"Delete Bob? This cannot be undone."` → two rows) — no
   `data-turbo-confirm` call site needed any change. A message with no second sentence (e.g.
   `"Suspend Bob?"`) correctly renders as a single row.
2. The message rows sit in a bordered, tinted box (`--color-surface-raised` background,
   `--color-border` border) rather than floating directly on the card background.
3. Found and fixed a real bug: the Cancel/Confirm buttons only had `.btn-secondary`/`.btn-danger`
   and were missing the base `.btn` class, so they silently fell back to the browser's default
   font instead of the app's button font — same bug class as the pattern everywhere else in this
   codebase (`class="btn btn-danger"`, always both classes together).
4. Added icons — `circle-x` for Cancel, `check` for Confirm — matching the icon convention already
   used on other action buttons (e.g. the Cancel button in `people/edit.html.erb`).

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases (via `js: true` feature specs using
  `accept_confirm`/`dismiss_confirm`-equivalent interactions with the new dialog, not Capybara's
  native-confirm helpers, since those target `window.confirm` specifically)
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* All 10 existing call sites manually verified in a real browser
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
* Per-action button labels (e.g. "Delete" instead of a generic "Confirm") sourced from the
  triggering element rather than hardcoded generic text — nice-to-have, not required for v1.
  (Icons were added despite this — `circle-x`/`check` are generic enough not to require
  per-action labelling, so this doesn't conflict with staying zero-retrofit.)
* A "danger" vs. "neutral" visual variant if a future non-destructive confirm ever needs this
  dialog (all 10 current uses are destructive/irreversible actions)

# OPEN QUESTIONS
* ~~Does clicking the dimmed backdrop cancel the dialog, or only the explicit Cancel button /
  Escape key?~~ — RESOLVED: yes, backdrop click cancels, same as Escape/Cancel.
* ~~Primary button label: generic "OK"/"Confirm" for every dialog, or derive a more specific label
  per call site?~~ — RESOLVED: generic "Confirm"/"Cancel" for v1, no new data attribute — matches
  the Deferred section above.
* ~~`<dialog>` element vs. a plain styled overlay `div`~~ — RESOLVED: native `<dialog>` +
  `showModal()`. Worked well with Turbo in practice — no page-morphing/caching issues surfaced
  (the dialog is always closed again, by construction, before any navigation happens). The one
  real friction point was a Selenium/ChromeDriver test-visibility quirk (see Trigger API block
  above), not a Turbo interaction problem.
* ~~Should the dialog's primary button always use `--color-danger`?~~ — RESOLVED: yes for v1, all
  10 current uses are destructive — matches the Deferred section above.
