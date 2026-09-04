# TASK
* Plan the development of a [FEATURE] feature to be added to [APP NAME, or 'Global — shared across BergstromDomain'].
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
*(Fill in per feature — what should it do, from the user's point of view?)*
  * [What triggers it]
  * [What it shows/does]
  * [How the user dismisses it / how it resolves on its own]

---

# SCOPE
* Global (usable by any app) or scoped to a single app? [ ]
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase? List known call sites/pages before designing the new one, so this becomes a consolidation, not just an addition.
* Which apps/pages/controllers does this touch once built?
* Any apps deliberately excluded for now?

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
*(Fill in — this replaces a full Data Model / CRUD block for features with no persistent entity. Add a Data Model section back in if the feature does need one, e.g. a notification history.)*
* Trigger(s): [what causes it to appear — e.g. after a successful/failed form submission]
* Variants/types: [e.g. success, error, warning, info — and how each is visually distinguished]
* Content: [text, icon, optional action link?]
* Placement: [where on screen]
* Timing: [auto-dismiss after N seconds? manually dismissible? both?]
* Stacking: [what happens with multiple simultaneous instances — queue, stack, replace?]
* Persistence across navigation: [does it survive a Turbo visit / page reload, or is it tied to the current page render?]
* Edge cases: [e.g. triggered during a Turbo Stream update, triggered twice in quick succession, triggered with no user signed in]

---

# INTEGRATION / MIGRATION
* Call sites to retrofit onto the new pattern (fill in from the Scope audit):
  * [ ] [Controller/action/page]
  * [ ] [Controller/action/page]
* Rollout approach: [big-bang replace vs incremental per-app migration]
* Anything that must keep working unchanged during the transition?

---

# DEVELOPMENT BLOCKS

## Core Component
* Partial/component structure
* Style variants (per type from Behaviour Spec)
* TBD — fill in per feature

## Trigger API
* How other code invokes this (helper method, concern, Stimulus event, etc.)
* Minimal interface a controller/view needs to call

## Behaviour / Interaction
* Show/dismiss logic (auto-timer, manual close, stacking) per Behaviour Spec

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
*(Running log of unresolved design questions raised during planning.)*
*
