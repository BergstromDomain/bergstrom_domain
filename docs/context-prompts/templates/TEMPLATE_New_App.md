# TASK
* Plan the development of a [DESCRIPTION] app to be integrated into BergstromDomain.
* The app should be named [APP NAME] and added to 'TopNav >> Apps', sorted alphabetically among existing apps.
* Outline the main development blocks for the app before writing any code.
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this app needs an exception to any of these.

---

# APP DESCRIPTION
*(Fill in per app — what should users be able to do?)*
  * Create [ITEM] (Draft by default / other initial state)
  * Publish [ITEM]
  * Edit both Draft and Published [ITEM]
  * Delete own [ITEM]
  * [Ownership model — single author? shared/co-author edit rights?]
  * [Content format(s) — Raw/Markdown vs Formatted/WYSIWYG, if applicable]
  * [Content types supported — text, images, video, tables, links, embedded documents]
  * [Metadata fields — author(s), taxonomy, status, created date, counters]
  * Browsing and filtering by [dimensions]
  * Searching ([fields] for [terms])

---

# DESIGN GUIDELINES
- Use the existing Authentication and Authorisation model (global roles: Visitor, App User, Content Creator, Admin, System Admin).
- Use the existing Data Classification model (Private / User's Circle / Public).
- The app should have its own landing page, consistent with other apps' landing pages.
- The app should have a left nav bar, consistent with other apps (see Left Navbar block).
- Follow the established design system (warm off-white palette, terracotta accent, Lucide icons, `.show-panel` / `.resource-form` conventions) — flag if this app needs a deliberate departure.
- [Any app-specific guideline, e.g. mobile/responsive priority, offline support, embed restrictions]

---

# PERMISSIONS MATRIX
*(Fill in — replaces scattering permission rules through prose below. One row per action.)*

| Action | Visitor | App User | Content Creator | Admin | Sys Admin |
|---|---|---|---|---|---|
| View published [ITEM] | | | | | |
| Create [ITEM] | | | | | |
| Edit own [ITEM] | | | | | |
| Edit others' [ITEM] (co-author) | | | | | |
| Publish/Unpublish [ITEM] | | | | | |
| Delete own [ITEM] | | | | | |
| CRUD [Taxonomy] | | | | | |
| Comment | | | | | |
| Restore soft-deleted [ITEM] | | | | | |

---

# DATA MODEL
*(Fill in before the CRUD blocks — don't let schema decisions hide inside UI descriptions.)*
* Entities and key fields: [ITEM], [Taxonomy], Comment, Reaction, etc.
* Relationships: e.g. [ITEM] has_many :authors through join table; [ITEM] belongs_to :[taxonomy leaf]
* Soft-delete / retention rules: [e.g. deleted [ITEM] retained N days, restorable by Admin]
* Any denormalised/cached counters (comment count, reaction score) and how they're kept in sync

---

# DEVELOPMENT BLOCKS

## Create [ITEM]
* Title Frame
  * Title — String — Mandatory
  * [ITEM] Image — Upload image — Optional
* Metadata Frame
  * [ITEM] Category — Dropdown list — Optional for create, Mandatory for publishing
    * Categories are created by Admins, consistent with existing taxonomy patterns (e.g. Event Types)
* [ITEM] Content Frame
  * TBD — fill in per app (body/content fields, format toggle if applicable)
* Action Frame
  * Cancel | Save | Publish

## List [ITEM]
* Columns to display: TBD

## Read [ITEM]
* Title Frame
  * Title — String — Mandatory
  * Image — Image — if none, show Category icon if selected, else blank
* Metadata Frame
  * [Taxonomy path] — show populated levels only
  * Main Author — String
  * Comment Count
  * Reaction/Like Count
* Content Frame
  * Formatted content
  * Like/React control
* Comments
  * List of comments
* Action Frame
  * Back to [Index] | Edit | Publish/Unpublish | Delete — see Permissions Matrix for who sees what; Publish/Unpublish label depends on current status

## Publish [ITEM]
Data validation for Publish:
* Unique '[User: Title]' (or other uniqueness rule)
* Category/taxonomy present
* Content present

## Edit [ITEM]
* After each edit, [ITEM] reverts to Draft — confirm whether this is desired for this app
* Any listed co-author can edit

## Delete [ITEM]
* Any listed co-author can delete
* Deleted [ITEM] retained for 7 days, restorable by Admins (confirm retention period per app)

## CRUD [Taxonomy]
* Consistent behaviour with existing taxonomy management (e.g. Event Types)
* Available to Admin and Sys Admin only (confirm against Permissions Matrix)

## Reactions / Likes — *EXAMPLE (Chronicles), adapt or remove per app*
* At the bottom of a post, show 5 faces: grinning, slightly-smiling, neutral, slightly-frowning, angry
* Signed-in user's default status is neutral, indicated by highlighting the selected icon
* User can change status any time; changing it updates the highlighted icon and the post's stats
* Score = weighted sum (grinning=5, slightly-smiling=4, neutral=3, slightly-frowning=2, angry=1) ÷ number of users in the system
* Display score as 1-decimal value (e.g. 3.2) with the icon matching that value under normal rounding

## Comments — *EXAMPLE (Chronicles), adapt or remove per app*
* Signed-in users can comment on [ITEM]
* Each comment shows: author thumbnail + full name + created date (`dd-MMM-yyyy`), comment text, and actions (Reply | Edit — author only | Delete — author only)
* Comment count wording: "1 comment in 1 thread" / "2 comments in 1 thread" (thread = a top-level comment + its replies)
* New top-level comments appear at the top; oldest at the bottom
* Replies are indented under their parent comment
* Deleting a top-level comment deletes all its replies

## Browsing — *EXAMPLE (Chronicles), adapt or remove per app*
* Taxonomy levels: Category / Subject / Topic
* Replace the [ITEM] index page with a drill-down tree showing item counts per node; clicking a node navigates one level down, ending in a list of [ITEM] at the leaf
* Breadcrumb path is clickable, each segment returning to that level of the tree
* Leaf-level table columns: Title (linked) | Author (icon + name) | Created (`dd-MMM-yyyy`) | Comments | Reaction score

## Filtering — *reusable pattern, worth keeping across apps*
* Toggle between 'Basic' and 'SQL' modes
  * Basic: dropdowns per taxonomy level (each defaulting to 'All X') + Author + Created (Today / This Week / This Month / This Year / Anytime)
  * SQL: free-text field for simple query syntax (JQL-like), for power users
* Result table: same sortable columns as the Browsing leaf-level table

## Left Navbar
Consistent structure with other apps (e.g. Event Tracker):
* VIEWS (H1)
  * [App Name] (H2) → landing page
  * [Item plural] (H2) → Browse / Filter links
  * My [Item plural] (H2) → My Published / My Unpublished (= Filtered view, author = current user)
  * [Taxonomy] (H2) → management link
* ACTIONS (H1, signed-in only)
  * Create [ITEM]
  * Create [Taxonomy entry]
* EXPORTS (H1, signed-in only)
  * Download [Item plural] — [formats, e.g. PDF via print, CSV with raw content]
* HOW TO (H1)
  * User Guide (may be a placeholder until written)

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* Permissions Matrix respected and covered by tests for each role
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
* [e.g. Filtering — Basic mode only for v1, SQL mode deferred]
* [e.g. User Guide content]

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
*
