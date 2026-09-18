# TASK
* Plan a rewrite of the Likes feature, to be shared across apps (Chronicle today; Cookbook and
  future apps going forward) — raised during Cookbook planning
  (`docs/context-prompts/active/App_-_Cookbook.md`) when Cookbook's own "same Likes as Chronicle"
  requirement ran into Likes being hard-wired to `BlogPost` (`belongs_to :blog_post`), not
  reusable as-is.
* **Confirmation gate:** before starting a new development block, summarise what you know so far
  (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open
  design questions before progressing. Do not skip ahead to implementation on an unconfirmed
  block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor),
  the four-section spec structure (Happy / Negative / Alternative / Edge), the
  `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop →
  rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* Current behaviour (Chronicle, shipped): 5 reactions (grinning=5 .. angry=1, `Like::FACES`),
  not a simple thumbs-up count. Signed-in users pick a face; it can be changed any time.
  Guests see the same 5-face row, highlighted to the post's aggregate face, non-clickable.
* **This doc exists because the user wants to rewrite this "a bit"** — specifics not yet
  captured; see Open Questions below. Nothing in this section should be assumed still correct
  until confirmed.

## Changed behaviour
* Like default value to be 'null', i.e. no `Like::FACES` selected
* Add a 'clear' icon (icon: circle-x, font red) to the right of the Like::FACES, allowing the user to clear his/her like
* Aggregarted calculation should be updated and only count the actual likes per value
* Make the Likes value in the meta data frame clickable to how breakdown
  * When clicking on the Like value, a popup with details about the likes should be shown
    Example @docs/context-prompts/Review.png
    Each of the 5 reactions to be shown together with a count and a bar
    Total score and total number of likes and the 'combined like face'

* Update the like function so that it can be used for other apps as well.
* **Resolved 2026-09-19:** rename the metadata panel's label from "Likes" to "Reactions"
  (`app/views/blog_posts/show.html.erb`'s `show-meta-cell__label`, currently "Likes" at line 68).
  Scoped to that panel's label text — the "React to this post" panel heading is unaffected (it
  already says "React"), and this doc keeps calling the underlying model/feature "Likes"
  (`Like`, `LikesController`, etc.) unless told otherwise.

---

# SCOPE
* Global — shared across apps (Chronicle now; Cookbook and future apps as they ship), not a
  single-app feature.
* **Existing pattern audit** (`app/models/like.rb`, `app/controllers/likes_controller.rb`,
  as of 2026-09-17):
  * `Like belongs_to :blog_post` and `belongs_to :user` — not polymorphic, so no other model can
    use it today without a schema change.
  * `Like::FACES` hash: `grinning`(5)/`slightly_smiling`(4)/`neutral`(3)/`slightly_frowning`(2)/
    `angry`(1), each with a Lucide `icon` + `color` hex.
  * Score formula: a user who has never reacted counts as an implicit neutral (3) vote —
    `score = (explicit points + 3×non-voters) / User.count`. No `Like` row is written just from
    viewing a page.
  * `validates :user_id, uniqueness: { scope: :blog_post_id }` — one Like per user per post.
  * No `likes_count` cached column (dropped during Chronicle's build — never fit a live-computed
    decimal average).
  * Rendered on Chronicle's Show page, and as a "Smiles" column on Browse/Filter — colored via
    `.like-face--<face>` CSS classes.
* Cookbook's own Read-a-Recipe page will ship with a **static, non-interactive placeholder**
  in the Likes' position until this feature is designed and built — not a functioning Like
  control. Revisit Cookbook's Read page once this feature ships.
* Which apps/pages does this touch once built: Chronicle (retrofit existing), Cookbook (new),
  any future app (Docket/Gallery) that wants reactions.
* **Resolved 2026-09-19 — this block's scope:** rewrites the shared/polymorphic Like engine and
  retrofits Chronicle only. `Recipe` doesn't exist yet (Cookbook is still planning-only, per
  `App_-_Cookbook.md`), so nothing gets wired into Cookbook as part of this block. Once this
  feature ships, add a note to `App_-_Cookbook.md` recording that its Likes dependency is
  resolved and the static placeholder can be replaced.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components rather than introducing new ones — flag if this
  rewrite genuinely needs a new token/pattern.
- Consistent with [[toast_feature_shipped]] (`Toastable`) if any user-facing success/error
  feedback is needed for a Like action — unlikely given it's currently a silent inline toggle,
  but confirm.
- **Resolved 2026-09-19:** the Comments generalization is a separate, later feature — spun out
  into `docs/context-prompts/active/Update_Feature_-_Comments.md` — not something Likes is paired
  with or blocked on. Likes proceeds with its own `belongs_to :likeable, polymorphic: true`
  conversion now, independently. (That doc notes Likes' shape as a precedent Comments may want to
  mirror, but the reverse dependency does not exist.)

---

# BEHAVIOUR SPEC
* **Reaction row** (unchanged position — Chronicle's "React to this post" panel):
  * Signed-in: 5 face buttons (unchanged icons/points/colors) + a new clear button (`circle-x`
    icon, red) to their right. Clicking a face sets/changes the user's `Like#face`; clicking clear
    sets it to `null` (row stays, per the resolved decision above).
  * Guest: same 5-face row, highlighted to the post's aggregate face, non-clickable, no clear
    icon (guests can't have a reaction to clear). **Resolved 2026-09-19:** when a post has zero
    site-wide reactions, the row is hidden entirely for guests (nothing to highlight, so nothing
    to show).
  * **Resolved 2026-09-19:** clicking the face that's already your active reaction is a no-op
    (re-submits the same face) — only the dedicated clear icon sets it to `null`.
* **Reactions meta panel value** (Chronicle Show page's meta data frame — label renamed from
  "Likes" to "Reactions", per the resolved decision above):
  * Zero reactions: "No reactions yet" (resolved above) instead of a computed score/face.
  * One or more reactions: score + combined face icon, as today — but computed only from rows with
    a non-null face — now clickable, opening the breakdown popup.
* **Breakdown popup** (new generic Popup component, Likes as first consumer — modeled on
  `Review.png`):
  * Trigger: click on the Likes meta panel value (only when it's non-empty — "No reactions yet"
    isn't clickable, nothing to break down).
  * Content: left side — total score, total number of likes, combined like face; right side — one
    row per `Like::FACES` entry, each with its icon, count, and a proportional bar.
  * Dismissal: **assumption carried forward** — standard modal conventions (close button, Esc key,
    backdrop click), matching whatever the new generic Popup component settles on; this is a
    property of the Popup component itself, not Likes-specific. Flag if Likes needs different
    dismissal behavior.
  * Stacking/persistence: single popup at a time; not persisted across navigation (closes on Turbo
    visit like the rest of the page).
* Edge cases: guest visits a post with zero reactions (see Open Questions); a user's own reaction
  changing mid-session while the breakdown popup is open (out of scope — popup reflects the state
  at open time, no live update needed); a post with reactions but all from a single face (the
  4 empty face rows in the popup still render at zero, per `Review.png`'s own display of empty
  star rows).

---

# INTEGRATION / MIGRATION
* Call sites to retrofit:
  * [ ] `app/models/like.rb`, `app/controllers/likes_controller.rb` — generalize from
    `blog_post_id` to a polymorphic association (if confirmed)
  * [ ] Chronicle's Show/Browse/Filter Likes rendering — repoint at the new association shape
  * [ ] Existing Like specs (model + feature) — update for the new schema
* Rollout approach: **Resolved 2026-09-19** — existing `likes` data in this environment is dummy
  data with no need to preserve, so the polymorphic conversion can be a clean/destructive schema
  change (drop and recreate the relevant columns) rather than a data-preserving backfill
  migration.

---

# DEVELOPMENT BLOCKS

*Blocks 1 & 2 touched: `db/migrate/20260918231600_convert_likes_to_polymorphic.rb`,
`app/models/like.rb`, `app/models/concerns/likeable.rb` (new), `app/models/blog_post.rb`,
`app/controllers/likes_controller.rb`, `config/routes.rb`,
`app/views/blog_posts/{show,index,filter}.html.erb`, `app/assets/stylesheets/application.css`,
and the corresponding specs (`spec/models/like_spec.rb`,
`spec/models/concerns/likeable_spec.rb` (new), `spec/models/blog_post_spec.rb`,
`spec/features/blog_posts/{like_blog_post,browse_blog_posts,show_blog_post}_spec.rb`,
`spec/services/blog_post_filter_spec.rb`, `spec/factories/likes.rb`). Full suite green
(1722 examples, 0 failures, 9 pre-existing unrelated `xit` pending), 95.9% coverage; RuboCop,
Brakeman, bundler-audit all clean. Not yet manually browser-verified — flagged separately.*

## Block 1 — Polymorphic Like model + nullable face + clear ✅ Done 2026-09-19
* Migration: destructive rename `likes.blog_post_id` → `likes.likeable_type`/`likes.likeable_id`
  (dummy data, no backfill needed per the resolved Rollout approach); `face` becomes nullable, no
  default (drop the `'neutral'` default).
* `Like belongs_to :likeable, polymorphic: true` (replacing `belongs_to :blog_post`); uniqueness
  validation moves to `scope: [:likeable_type, :likeable_id]`.
* `LikesController` generalizes from `set_blog_post`/`blog_post_id` params to a polymorphic
  `likeable` lookup; add a `clear` action (or extend `create` to accept a null/clear face) setting
  `face` to `null` instead of requiring a `Like::FACES` key.
* Update `BlogPost#like_score`/`#like_score_face`/`#current_user_face` (or extract to a shared
  `Likeable` concern other models `include`) to: drop the implicit-neutral-vote-for-non-voters
  formula, count only rows with a non-null `face`, and handle the zero-reactions case explicitly
  (feeds Block 2's "No reactions yet").
* Retrofit Chronicle's Show/Browse/Filter Likes rendering to the new association/controller shape,
  including the new clear button.
* Update existing Like model/controller/feature specs for the new schema and behaviour.

## Block 2 — "No reactions yet" empty state + guest visibility ✅ Done 2026-09-19 (folded into Block 1)
* **Plan correction:** this turned out not to be separable from Block 1. The moment
  `like_score`/`like_score_face` can return `nil`, every existing Show/Browse/Filter view call
  site (`Like::FACES[post.like_score_face][:icon]`) crashes on any post with zero reactions — and
  a freshly created post has zero reactions by default now, so this wasn't an edge case to defer,
  it was the common case. Implemented both pieces as part of Block 1's view retrofit instead of a
  separate block:
  * Meta panel shows "No reactions yet" when `like_score` is `nil` (Show/Browse/Filter, all
    consistently).
  * Reaction row is hidden entirely for a guest when there's no aggregate face to highlight
    (`authenticated? || highlighted_face.present?`).

## Block 3 — Generic Popup component
* New reusable Popup/Modal component (partial + Stimulus controller), independent of Likes'
  content — establishes open/close/dismissal conventions (close button, Esc, backdrop click) as a
  general-purpose pattern other features can reuse later.
* No Likes-specific content yet — this block is provable on its own with a minimal
  trigger-and-content smoke test.

## Block 4 — Likes breakdown popup content
* Wire the Likes meta panel value (when non-empty) to open the new Popup component.
* Popup content per `Review.png`: total score / total likes / combined face on one side, each of
  the 5 `Like::FACES` with count + proportional bar on the other.
* Feature specs covering the popup's Likes-specific content and the click-to-open trigger.

---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* All retrofitted call sites verified, old pattern fully removed (no dual implementations left
  behind)
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
* Cookbook ships with a static Likes placeholder on Recipe's Read page until this feature lands.

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* ~~What specifically should change from the current 5-face/weighted-average behaviour?~~ —
  resolved via the Changed Behaviour list under Feature Description.
* ~~Should Likes become polymorphic (`likeable`), matching the Comments generalization decision~~
  — resolved: yes, Likes goes polymorphic now, independently of Comments (see Design Guidelines).
* ~~Does a cross-app rewrite need a data migration plan for Chronicle's existing `likes` rows~~ —
  resolved: no, existing data is dummy data, a clean/destructive migration is fine (see
  Integration/Migration).
* ~~When a user clicks the new "clear" icon, does the Like row get deleted entirely~~ — resolved
  2026-09-19: the row stays, `face` is set to `null`, distinguishing "explicitly cleared" from
  "never voted".
* ~~What should the meta panel show for a post with zero reactions~~ — resolved 2026-09-19: show
  "No reactions yet".
* ~~Build a generic reusable Popup/Modal component, or keep the breakdown popup Likes-specific~~ —
  resolved 2026-09-19: build a generic reusable Popup component, with Likes as its first consumer.
* ~~Any change to guest visibility~~ — resolved 2026-09-19: guests see the row hidden entirely
  when a post has zero site-wide reactions (see Behaviour Spec).
* ~~Does clicking your own already-active face clear it, or only the dedicated clear icon~~ —
  resolved 2026-09-19: only the clear icon removes a reaction; re-clicking your active face is a
  no-op.

All open questions resolved as of 2026-09-19 — ready to start Block 1.
