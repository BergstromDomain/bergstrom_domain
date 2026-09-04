# TASK
* Plan the development of a Toast feature to be added to Event Tracker and Chronicle apps.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
The toast should be displayed on Create, Update and Delete for all items in both the Event Tracker and the Chronicle apps (and future apps later on)
  * What triggers it?
    * Create [Person | Event | Event-Type | Post | Category]
    * Update [Person | Event | Event-Type | Post | Category]
    * Delete [Person | Event | Event-Type | Post | Category]
  * What it shows/does?
    * "[@Person | @Event | @Event-Type | @Post | @Category] has been successfully created"
    * "[@Person | @Event | @Event-Type | @Post | @Category] has been successfully updated"	Note: Display the new value when applicable
    * "[@Person | @Event | @Event-Type | @Post | @Category] has been successfully deleted"	
  * How the user dismisses it / how it resolves on its own
    * Toast message should automatically fade away after 3 seconds
---

# SCOPE
* Global (usable by any app) 
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase?
* This should replace existing flash messages on the apps

---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
*(Fill in — this replaces a full Data Model / CRUD block for features with no persistent entity. Add a Data Model section back in if the feature does need one, e.g. a notification history.)*
* Trigger(s): [Created, Edited, Deleted, Published, Unpublished]
* Variants/types: [e.g. success - Green, error - Red, warning - Orange, info — Blue]
* Content: [Header: Success|Error|Warning|Info + icon, Message on a separate row]
* Placement: [Just below the top navbar, aligned center]
* Timing: [auto-dismiss after 3 seconds and manually dismissible]
* Stacking: [what happens with multiple simultaneous instances — Stack]
* Persistence across navigation: [tied to the current page render]
* Edge cases: [e.g. triggered during a Turbo Stream update, triggered twice in quick succession, triggered with no user signed in]

---

# INTEGRATION / MIGRATION


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
