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
- Use existing design system tokens/components rather than introducing new ones — this is a pure
  backend/association-shape change, no new UI at all, so this doesn't apply in practice.
- **Confirmed 2026-09-20**: mirrored Likes' polymorphic shape exactly — `Commentable` concern
  (named after itself, like `Likeable`), `commentable` polymorphic association, same migration
  pattern (`ConvertLikesToPolymorphic` → `ConvertCommentsToPolymorphic`).

---

# BEHAVIOUR SPEC
* Confirmed 2026-09-20: unchanged from current behaviour in
  every respect except the association shape itself. No new Comment features, no UI changes on
  Chronicle's Show page — `pluralize(@blog_post.comments_count, "comment")`,
  `comments.top_level.count`, `comments.threads_ordered`, reply/edit/delete permission checks all
  keep working exactly as today, just resolved through `commentable` instead of `blog_post`.
* Threading (2-level thread + flat replies, `parent_must_be_top_level`) is unaffected — it's
  self-referential and doesn't touch the `commentable` association at all.
* `counter_cache: true` continues to work on the polymorphic association (Rails increments/
  decrements whatever column name is passed on the *current* `commentable_type`'s table) — but
  this means every future commentable host (Cookbook's `Recipe`) must define its own
  `comments_count` column when it adds `include Commentable`, the same way `Like`'s polymorphic
  conversion didn't need this (it has no counter cache) but Comments' does. Flag this explicitly
  in `App_-_Cookbook.md`'s Foundation block (Block 0) once this ships, so it isn't missed when
  `Recipe` is created.

---

# INTEGRATION / MIGRATION
* Call sites to retrofit (audited 2026-09-20 against current `main`, post-PR-#73):
  * [x] **Migration** — mirror `db/migrate/*_convert_likes_to_polymorphic.rb` exactly (same shape,
    `Comment`/`comments` instead of `Like`/`likes`):
    `rename_column :comments, :blog_post_id, :commentable_id`; add `commentable_type` with a
    temporary `default: "BlogPost"` (backfills existing rows) then drop the default; add index on
    `%i[commentable_type commentable_id]`. Unlike `likes`, there's no unique-per-user index to
    juggle (a user can post unlimited comments), so this migration is actually simpler than
    Likes' — no index drop/recreate around a uniqueness constraint.
  * [x] `app/models/concerns/commentable.rb` — new concern mirroring `app/models/concerns/likeable.rb`:
    `has_many :comments, as: :commentable, dependent: :destroy`. `include Commentable` on
    `BlogPost` (replacing its current bare `has_many :comments, dependent: :destroy`).
  * [x] `app/models/comment.rb` — `belongs_to :blog_post, counter_cache: true` → `belongs_to
    :commentable, polymorphic: true, counter_cache: true`
  * [x] `config/routes.rb` — `resources :comments, only: %i[create update destroy], shallow: true`
    stays nested under `resources :blog_posts` (shallow routing already means only `create` needs
    `blog_post_id` in the path; `update`/`destroy` already resolve via bare `comment_path`, no
    route change needed there). No route rename needed since the nesting is keyed by the parent
    resource's name, not the association name.
  * [x] `app/controllers/comments_controller.rb` — `set_blog_post`/`@blog_post` →
    `set_commentable`/`@commentable` (`BlogPost.friendly.find(params[:blog_post_id])`, same
    "blog-post-specific until another app adds its own nested :comment route" caveat comment as
    `LikesController#set_likeable` carries today — Cookbook's own `Recipe` wiring is out of scope
    here, same precedent as Likes). `comment.blog_post` references throughout (`redirect_to
    @comment.blog_post`) → `@comment.commentable`.
  * [x] `app/views/comments/_form.html.erb`, `app/views/comments/_comment.html.erb` — `blog_post:`
    locals/params → `commentable:`; `blog_post_comments_path(blog_post)` →
    `blog_post_comments_path(commentable)` (path helper name unchanged, only the local var renamed)
  * [x] `app/views/blog_posts/show.html.erb` (lines ~139-153) — `@blog_post.comments`/
    `comments_count` calls are on `BlogPost` itself, not renamed — unaffected apart from passing
    `commentable: @blog_post` instead of `blog_post: @blog_post` into the two partial renders
  * [x] `spec/factories/comments.rb` — `association :blog_post` → `association :commentable,
    factory: :blog_post` (mirrors `spec/factories/likes.rb`'s equivalent post-conversion shape —
    verify that file's exact syntax when implementing)
  * [x] `spec/models/comment_spec.rb` — `belong_to(:blog_post).counter_cache(true)` →
    `belong_to(:commentable).counter_cache(true)`; all `create(:comment, blog_post: post, ...)` →
    `create(:comment, commentable: post, ...)`
  * [x] `spec/features/blog_posts/comment_blog_post_spec.rb` — no association-shape references
    expected (drives through the UI), but re-run to confirm
* Rollout approach: **confirmed 2026-09-20** — same precedent as Likes
  (`docs/context-prompts/archive/Update_Feature_-_Likes.md`): existing `comments` data in this
  environment is dummy data with no need to preserve. Destructive rename/backfill migration used,
  applied to both dev and test databases.

---

# DEVELOPMENT BLOCKS
Single block, since this is scoped as a pure mechanical generalization with no new behaviour
(unlike Likes, whose rewrite bundled in genuine feature changes — nullable face, clear icon,
breakdown popup — across 4 blocks; nothing here called for splitting):

0. **Done, 2026-09-20.** Generalize `Comment` to polymorphic `commentable` — migration,
   `Commentable` concern, model/controller/view/route retrofit, spec updates (all call sites
   listed under Integration/Migration above). Full suite green (1784 examples, 0 failures, 9
   pre-existing pending), coverage 96.0% (not regressed). RuboCop/Brakeman/bundler-audit clean.
   `rails runner` sanity check confirmed `commentable_type`/`commentable_id`/`comments_count`
   behave correctly end-to-end in the dev database. Manual browser click-through of Chronicle's
   comment/reply/edit/delete flows still pending (sandbox can't drive a live browser — see note
   below).

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
* ~~Is this a pure mechanical generalization (rename association, no behaviour change), or is
  there a "changed behaviour" wishlist for Comments the way there was for Likes?~~ — resolved
  2026-09-20: pure mechanical generalization, no behaviour change.
* ~~Should the polymorphic association name/shape deliberately mirror Likes' (`likeable`) for
  consistency, e.g. `commentable`?~~ — resolved 2026-09-20: yes, `commentable`/`Commentable`
  concern, same migration shape as `ConvertLikesToPolymorphic`.
* ~~Does existing Chronicle comment data need to be preserved through the migration, or — per the
  precedent set while planning Likes — is it dummy data that can be dropped/recreated?~~ —
  resolved 2026-09-20: dummy data, destructive rename migration used.
* ~~Sequencing: does this need to land before Cookbook's Recipe Comments block (as
  `App_-_Cookbook.md` currently assumes), or can Cookbook's Comments wait until this ships
  independently of that timeline?~~ — resolved 2026-09-20: lands before Cookbook's Recipe
  *Comments* block (Block 7) — done now, well ahead of that.
* ~~The polymorphic `counter_cache` means every future commentable host must carry its own
  `comments_count` column~~ — resolved 2026-09-20: noted for `App_-_Cookbook.md`'s own Foundation
  block (Block 0) when `Recipe` is created; no action needed in this doc beyond flagging it there.

All open questions resolved as of 2026-09-20 — Block 0 complete, only the manual browser
click-through remains before this can be considered fully done.
