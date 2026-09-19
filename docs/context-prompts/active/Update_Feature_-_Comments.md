# TASK
* Plan the generalization of `Comment` from being hard-wired to `BlogPost`
  (`belongs_to :blog_post`) into a polymorphic `belongs_to :commentable, polymorphic: true`,
  shared across apps (Chronicle today; Cookbook and future apps going forward).
* Spun out of `docs/context-prompts/active/Update_Feature_-_Likes.md` (2026-09-19): that doc
  originally assumed Comments were "being generalized to polymorphic at the same time, for the
  same reason" as Likes — that assumption was stale (the code was still `belongs_to :blog_post`
  when checked) and the two rewrites are now tracked as separate features. Likes proceeds with
  its own polymorphic conversion independently; do not block Likes on this doc.
* Also referenced by `docs/context-prompts/active/App_-_Cookbook.md` (Development Block 2 —
  "Generalize Comments to polymorphic"), which is sequenced before Cookbook's own Recipe Comments
  block (Block 7). Update that doc's block description to point here once this plan is fleshed
  out.
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
* Current behaviour (Chronicle, shipped): `Comment belongs_to :blog_post, counter_cache: true`,
  `belongs_to :user`, optional `belongs_to :parent` (2-level thread + flat replies, enforced by
  `parent_must_be_top_level`). Rendered via `comments/comment` and `comments/form` partials on
  Chronicle's Show page.
* Not yet captured: whether the rewrite is a pure mechanical generalization (rename association,
  keep all existing behaviour) or whether anything about Comments' behaviour itself should change
  along the way — TBD, see Open Questions.

---

# SCOPE
* Global — shared across apps (Chronicle now; Cookbook and future apps as they ship).
* **Existing pattern audit** (`app/models/comment.rb`, as of 2026-09-19):
  * `belongs_to :blog_post, counter_cache: true` — the `counter_cache` needs a matching column on
    whatever polymorphic host type is added (today: `BlogPost#comments_count`).
  * `has_rich_text :body` (Action Text) — unaffected by the association shape.
  * Threading (`parent`/`replies`) is self-referential, independent of the `blog_post` association
    — should carry over unchanged.
* Which apps/pages does this touch once built: Chronicle (retrofit existing), Cookbook (new, per
  `App_-_Cookbook.md` Block 7), any future app that wants comment threads.

---

# DESIGN GUIDELINES
- Use existing design system tokens/components rather than introducing new ones — flag if this
  rewrite genuinely needs a new token/pattern.
- Confirm whether Likes' own polymorphic shape (`Update_Feature_-_Likes.md`) should be mirrored
  exactly (both use `likeable`/`commentable` polymorphic associations named after their own
  concern) now that the two are being built separately, so the two conversions don't diverge for
  no reason.

---

# BEHAVIOUR SPEC
*(TBD — fill in once scope is confirmed; likely "unchanged from current behaviour" for most of
this section, since this is primarily an association-shape generalization.)*

---

# INTEGRATION / MIGRATION
* Call sites to retrofit:
  * [ ] `app/models/comment.rb` — `belongs_to :blog_post, counter_cache: true` → `belongs_to
    :commentable, polymorphic: true, counter_cache: true` (if confirmed)
  * [ ] Chronicle's Show page comment rendering (`comments/comment`, `comments/form` partials) —
    repoint at the new association shape
  * [ ] Existing Comment specs (model + feature) — update for the new schema
* Rollout approach: TBD. Note the precedent set in `Update_Feature_-_Likes.md`: existing
  `comments`/`likes` data in this environment is dummy data with no need to preserve, which may
  simplify this migration too (destructive column rename instead of a data-preserving backfill) —
  confirm the same applies here before assuming it.

---

# DEVELOPMENT BLOCKS
*(Not started — TBD once Open Questions are answered.)*

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
*

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
* Is this a pure mechanical generalization (rename association, no behaviour change), or is there
  a "changed behaviour" wishlist for Comments the way there was for Likes?
* Should the polymorphic association name/shape deliberately mirror Likes' (`likeable`) for
  consistency, e.g. `commentable`?
* Does existing Chronicle comment data need to be preserved through the migration, or — per the
  precedent set while planning Likes — is it dummy data that can be dropped/recreated?
* Sequencing: does this need to land before Cookbook's Recipe Comments block (as
  `App_-_Cookbook.md` currently assumes), or can Cookbook's Comments wait until this ships
  independently of that timeline?
