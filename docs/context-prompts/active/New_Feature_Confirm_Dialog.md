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
  (touch every call site) — there is no per-controller/per-view retrofit block for this feature.
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

## Core Component
* Dialog markup/partial — likely a `<dialog>` element (native focus trap + backdrop support) or a
  styled `div` overlay if `<dialog>` proves awkward with Turbo's timing — TBD, flag which was
  chosen and why.
* Stimulus controller: renders the dialog with the given message, resolves a Promise on
  confirm/cancel, handles Escape/backdrop-click per Open Questions.
* Style: backdrop, centered card, message text, button pair — using existing design tokens.

## Trigger API
* `Turbo.config.forms.confirm = async (message, element, submitter) => {...}` registered once,
  globally (where — `application.js`, a new initializer, or inline in the Stimulus controller
  itself? TBD).
* No controller/view-facing API to design — the existing `data-turbo-confirm` attribute is the
  entire public interface, already used everywhere it's needed.

## Behaviour / Interaction
* Promise-based resolution wired to Turbo's `await confirmMethod(...)` contract.
* Focus trap, focus return on close, Escape/backdrop behavior per Open Questions.

## Manual Verification
* No "Retrofit Existing Usages" block needed (see Integration/Migration) — instead, manually
  exercise all 10 call sites in a real browser to confirm the dialog renders correctly and the
  underlying action still fires/cancels correctly for each.

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
  triggering element rather than hardcoded generic text — nice-to-have, not required for v1
* A "danger" vs. "neutral" visual variant if a future non-destructive confirm ever needs this
  dialog (all 10 current uses are destructive/irreversible actions)

# OPEN QUESTIONS
* Does clicking the dimmed backdrop cancel the dialog, or only the explicit Cancel button /
  Escape key? (Native `window.confirm` has no backdrop to click, so there's no existing behavior
  to match here — this is a genuinely new decision.)
* Primary button label: generic "OK"/"Confirm" for every dialog, or derive a more specific label
  per call site (e.g. "Delete", "Suspend", "Reject")? The latter is friendlier but means adding a
  new data attribute (e.g. `data-turbo-confirm-label`) to some or all of the 10 call sites, which
  would make this a small partial-retrofit after all.
* `<dialog>` element vs. a plain styled overlay `div` — `<dialog>` gives native focus-trap and
  top-layer stacking for free but needs checking against Turbo page-morphing/caching behavior;
  worth a spike before committing either way.
* Should the dialog's primary button always use `--color-danger` (all 10 current uses are
  destructive), or does that hardcode an assumption that breaks the first non-destructive
  confirm this gets used for?
