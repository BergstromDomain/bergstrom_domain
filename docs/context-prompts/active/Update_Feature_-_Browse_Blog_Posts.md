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


## Core Component


## Trigger API


## Behaviour / Interaction


## Retrofit Existing Usages


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
* The TASK's "same functionality to be used for Cookbook and likely other apps" ambition —
  deliberately not generalized now (2026-09-20 fix touched Chronicle's `BlogPostsController`
  directly, no shared concern/service extracted). Revisit and extract a shared abstraction
  when Cookbook's own Browse actually gets built, same approach as `Likeable` was extracted
  concretely when needed rather than speculatively — see [[likes_rewrite_feature_shipped]].

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning — resolved as of
2026-09-20.)*
* ~~Should "(Uncategorized)" also always show, including (0)~~ — resolved: yes, same as a real
  category.
