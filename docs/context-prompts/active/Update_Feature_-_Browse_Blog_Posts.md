# TASK
* Plan the development to update the Chronicle Browse Blog Posts feature. The same functionality to be used for Cookbook and likely for other apps in the future
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
* Update the page to include all Blog Categories together with the number of posts for each category
* Given that the number of categories are created by admins and are likely to remain below 30, this will likely fit nicely on one page
* This means the there will be categories with (0) posts
* When drilling down further there will not be any Subjects nor Topics with empty values since they are mapped to existing posts
* Deleted posts including the ones still availabe for admin to restore, should not be availble when browsing

## ✅ Done 2026-09-20 (Chronicle only — see Deferred for the cross-app part)
* **Resolved:** all four bullets above audited against the actual implementation:
  1. `BlogPostsController#category_counts` was dropping any category with zero visible posts
     (`if count.positive?`) — removed. Every `BlogCategory` now always shows.
  2. "(Uncategorized)" was the same — now always shows, including "(Uncategorized) (0)", per
     confirmation that it should behave the same as a real category for this purpose.
  3. Subjects/Topics already couldn't have empty entries — they're plain string columns on
     `BlogPost`, not their own records, so an "empty" one can't exist. No code change needed;
     confirmed via the existing `grouped_counts` implementation.
  4. **Found a real pre-existing bug, not just a restatement:** `BlogPost.visible_to_visitors`
     and the main branch of `.visible_to_users` had no `deleted_at` filter at all — only
     `.visible_to_admins` (`kept`) excluded soft-deleted posts. A published-then-soft-deleted
     post (within its 30-day admin-restorable window) was still visible to guests and regular
     signed-in users via Browse/Filter. Fixed by adding `.kept` to both scopes.
* Verified: new specs in `spec/models/blog_post_spec.rb` (soft-deleted-post exclusion for both
  scopes) and `spec/features/blog_posts/browse_blog_posts_spec.rb` (zero-count category and
  Uncategorized shown; soft-deleted post excluded from counts/listing); two existing specs that
  asserted the old "hide empty buckets" behavior were inverted rather than just deleted. Full
  suite green (803 non-feature + 980 feature examples, aside from pre-existing unrelated
  environmental flakiness); RuboCop/Brakeman/bundler-audit clean.

## Update 2026-10-10 — drill-down rework (planning, not started)
* Remove the concept of "(No Subject)" and "(No Topic)"
* All posts will have a Category
  * Remove "(Uncategorized)" — **supersedes** the 2026-09-20 decision above that it should
    always show, including "(Uncategorized) (0)"
* Navigating into a Category should show
  * All existing Subject(s) for the Category
  * The preview panel with all blog posts for the Category
* Navigating further into a Subject should show
  * All existing Topic(s) for the Subject
  * The preview panel with all blog posts for the Subject
* Navigating further into a Topic should show
  * The navigation bar
  * The preview panel with all blog posts for the Topic

### Current implementation (audited 2026-10-10)
* `BlogPostsController#index` drives all four levels off query params (`category_id`,
  `subject`, `topic`); the literal value `"none"` is the "(Uncategorized)" / "(No Subject)" /
  "(No Topic)" bucket (`find_category_from_param`, `grouped_counts`'s `v.presence || "none"`,
  `category_counts`'s `:uncategorized` key).
* Posts are only listed at the **Topic** (leaf) level today — `@posts` is set only when
  `topic` is present; Category and Subject levels show counts only. The leaf renders a plain
  breadcrumb (`data-testid="browse-breadcrumb"`) plus the `.blog-cards` card list.
* Category is only required on **publish** (`validates :blog_category, presence: true, if:
  :published?`). Drafts may have none, and both import paths rely on that: the CSV import
  leaves an unmatched/blank Category empty, and the ZIP import always leaves it empty for the
  user to fill in afterwards.
* Subject and Topic are optional plain string columns; `topic_requires_subject` already
  forbids a Topic without a Subject.
* Dev data (16 kept posts): 0 without a Category, 1 without a Subject, 11 without a Topic.
  Removing "(No Topic)" means most posts would no longer be reachable at Topic level, so the
  new Category/Subject preview panels are where they'd surface.


---

# SCOPE
* Global (usable by any app) or scoped to a single app? [ ]
* **Existing pattern audit:** is there already an ad hoc or inconsistent version of this in the codebase? List known call sites/pages before designing the new one, so this becomes a consolidation, not just an addition. If this feature is about user-facing success/error/info/warning notifications specifically, check first whether it's actually a new `Toastable` trigger (see `app/controllers/concerns/toastable.rb`) rather than a new pattern — most of that space is already covered.


---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- If this feature needs to notify the user of a success/error/info/warning outcome, use the existing global Toast component (`Toastable` concern + `shared/_toast` partial) rather than building a new notification pattern — see the Toast feature's own planning doc under `docs/context-prompts/` for the two invocation paths (flash-based vs. state-based) and how they were chosen.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Accessibility: [e.g. screen-reader announcement, keyboard dismissal, focus handling — confirm if relevant to this feature]
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC
* Edge cases: [e.g. triggered during a Turbo Stream update, triggered twice in quick succession, triggered with no user signed in]

---

# INTEGRATION / MIGRATION

---

# DEVELOPMENT BLOCKS

*(Proposed 2026-10-10 for the drill-down rework — awaiting confirmation, nothing started.)*

## Block 1 — Category mandatory on save (Chronicle) ✅ Done 2026-10-10
* Shipped as planned, with two adjustments: the form keeps a "Select a Category" **prompt**
  (plus `required`) rather than dropping the blank option, so an author can't silently save
  under whichever category is first alphabetically; the "(Uncategorized)" Browse bucket is
  left for Block 2's rewrite. Dev data: one soft-deleted post with no category ("Blog Post 1",
  id 8, past its purge window) was given "Arts & Culture" so the NOT NULL migration could run.
  Five specs covering category-less posts were removed (the state can no longer exist); the
  dead nil-category view/service branches went with them. Full suite: 2026 examples, 0
  failures, 96.49% coverage.
* `BlogPost`: `validates :blog_category, presence: true` on every save (drop `if: :published?`);
  migration adds `NOT NULL` to `blog_posts.blog_category_id` (safe, nothing in PROD).
  `BlogCategory has_many :blog_posts, dependent: :restrict_with_error` already stops a category
  that still has posts from being deleted, so no change is needed there.
* New/Edit Blog Post form: Category select becomes required (no blank option).
* CSV import: a blank or unmatched Category **fails the row** with a clear error, instead of
  leaving the post uncategorized (categories are admin-created, so import can't create one).
* ZIP import: never carries a Category, so the Import page gets a **Category select** used for
  `.zip` uploads (see open question A).
* Remove every remaining "(Uncategorized)" fallback (Filter Blog Posts and Download Blog Posts
  tables; Browse is handled in Block 2).
* `blog_post` factory: base definition gets a category (today only `:published` has one); fix
  any spec that relied on a category-less post.

## Block 2 — Shared Browse drill-down + Chronicle retrofit ✅ Done 2026-10-10
* Shipped: `BrowseTree` service (`app/services/browse_tree.rb`, `Level`/`Node` structs),
  `Browsable` concern (`load_browse_tree`, `browse_path_for`), shared partials in
  `app/views/shared/browse/` (`_tree`, `_tree_level`, `_breadcrumb`, `_preview_panel`), and
  Chronicle's card extracted to `blog_posts/_browse_card`. `BlogPostsController#index` is now a
  three-line call plus a `browse_levels` method; the old `find_category_from_param`/
  `grouped_counts`/`category_counts` helpers and all `"none"` handling are gone. An unknown
  Category in the URL (including the old `category_id=none`) redirects to the Browse root.
  Full suite: 2043 examples, 0 failures, 96.59% coverage.
* **Confirmed 2026-10-10:** tree above, preview panel below (Category/Subject levels); a level's
  preview panel includes **all** posts beneath it (not just those lacking a deeper value);
  panel heading "Posts in <name> (N)"; no preview panel at the root level.
* App-agnostic core, mirroring how `Jql::Evaluator`, `PdfRenderingService` and
  `ZipBundlingService` were built: a service describing an ordered list of levels. The first
  level is a reference-data association (every record listed, including (0)); later levels
  are optional string columns (Subject, Topic), and blank values are simply not listed as a
  level entry. Exposed through a `Browsable` controller concern plus shared partials (level
  list with counts, breadcrumb, preview panel that takes an app-specific card partial).
* Chronicle's `BlogPostsController#index` rebuilt on it. The Category, Subject and Topic
  levels each show the child list (where there is one) **plus** the preview panel of every
  post at that level, newest first. The Topic level shows the breadcrumb. All `"none"`
  handling is removed.
* Cookbook note, not built now: Cookbook's spec currently says Cuisine is "mandatory for
  Publishing but not for Create". The shared core simply leaves out records with a blank
  first level, so either choice works there. Decide when Cookbook is built.


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
* ~~Superseded 2026-10-10: the shared abstraction is now in scope (Block 2).~~ The TASK's "same functionality to be used for Cookbook and likely other apps" ambition —
  deliberately not generalized now (2026-09-20 fix touched Chronicle's `BlogPostsController`
  directly, no shared concern/service extracted). Revisit and extract a shared abstraction
  when Cookbook's own Browse actually gets built, same approach as `Likeable` was extracted
  concretely when needed rather than speculatively — see [[likes_rewrite_feature_shipped]].

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning — resolved as of
2026-09-20.)*
* ~~Should "(Uncategorized)" also always show, including (0)~~ — resolved: yes, same as a real
  category. **Superseded 2026-10-10:** "(Uncategorized)" is being removed entirely.

**Resolved 2026-10-10** (answers to the questions below, kept for the record):
1. Category is **mandatory on every save**, drafts included. The CSV template already lists
   every Category on its own example row.
2. Subject and Topic stay **optional**: a post without one is listed in the parent level's
   preview panel, with no "(No ...)" bucket.
3. Nothing is deployed to PROD yet, so no backfill is needed; a `NOT NULL` constraint is safe.
4. "Navigation bar" meant the **breadcrumb** (Categories › Category › Subject › Topic) at
   Topic level. Category and Subject levels keep their existing, different breadcrumb view.
5. Preview panel = the **existing `.blog-cards` card list**, newest first, no limit. Users
   who want something different use Filter Blog Posts.
6. **Keep showing every Category** on the top page, including ones with (0) posts.
7. **Make it shared**: Cookbook (Browse by Cuisine / by Food Type) and future apps will reuse it.

**Original questions:**
1. **When is Category required?** "All posts will have a Category" — required on every save
   (drafts too), or still only on publish (drafts without one just don't appear in Browse)?
   Requiring it on drafts affects the New Blog Post form and both import paths: CSV rows with
   a blank/unmatched Category would fail, and the ZIP path (which never carries a Category)
   would need a Category picker on the Import page or a default.
2. **Subject/Topic still optional?** Assumed yes: posts without a Subject/Topic simply appear
   in the parent level's preview panel rather than in a "(No ...)" bucket. Or should Subject
   and Topic become required too?
3. **Existing data:** any post without a Category (none in dev today, PROD unknown) needs a
   backfill decision before a validation/`NOT NULL` lands — data migration to a chosen
   category, or a manual fix-up step in the PROD readiness doc?
4. **"The navigation bar" at Topic level:** the existing breadcrumb (Categories › Category ›
   Subject › Topic)? And should Category and Subject levels show the same breadcrumb too, for
   consistency?
5. **Preview panel:** reuse the leaf's existing `.blog-cards` card list as-is at all three
   levels, or something more compact at Category/Subject level (e.g. title + metadata only)?
   Any ordering/limit (e.g. newest first, paginate past N)?
6. **Category level with zero posts:** still listed on the top page with "(0)", per the
   2026-09-20 decision? Clicking into it would show no Subjects and an empty preview panel.
7. **Cross-app reuse:** still deferred until Cookbook's Browse is built (see Deferred), or
   extract a shared concern as part of this rework?

**Open — Block 1 confirmation gate (2026-10-10):**
* A. **ZIP import Category:** add a Category select to the Import Blog Posts page, required
  only when the uploaded file is a `.zip` (a CSV carries its own Category per row)? The
  alternative is one select that applies to both, overriding the CSV's column, which seems
  worse.
* ~~B. CSV row with a blank or unmatched Category~~ — **resolved 2026-10-10:** only that row
  fails, with an error; the other rows still import.
* A (follow-up): the user answered "no picker needed — this is mostly Dev download → Prod
  upload, so posts will already have a Category". But the existing ZIP import is the
  single-Markdown-file path (Block 4 of Import/Export) and never carries a Category, while
  the Dev → Prod round trip would be the deferred admin Full *Import*. Asked: remove the
  Markdown ZIP import, add a Category select for .zip uploads, read Category from Markdown
  front matter, or leave it failing? **Resolved 2026-10-10: option 2** — a Category select on
  the Import page, required for `.zip` uploads (ignored for CSV).
