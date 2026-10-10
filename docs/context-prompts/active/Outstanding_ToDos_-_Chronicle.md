# Outstanding ToDos — Chronicle (Blog Posts)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Chronicle. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] `spec/features/blog_posts/create_blog_post_spec.rb` "Adds a confirmed contact as a
      co-author via the shuttle" (js: true) is `xit`-skipped: fails deterministically on CI
      (page stays on `/blog-posts/new` after Save, even with a 10s wait), never locally.
      Suspect the editor's async convert-before-submit in `blog_post_editor_controller.js`, or
      a Turbo 422 re-render. Next step: a temporary CI-side failure hook dumping path, field
      errors, title value, selected authors and browser console logs.
- [ ] The "Likes" → "Reactions" label rename (`docs/context-prompts/archive/Update_Feature_-_Likes.md`)
      only touched the Show page's metadata panel. Browse Blog Posts
      (`app/views/blog_posts/index.html.erb`) still labels it "Likes:", and Filter Blog Posts
      (`app/views/blog_posts/filter.html.erb`) still calls the same column "Smiles" (header and
      `filter_sort_link("smiles")`). Pick one consistent name and apply it everywhere
      `Like`/`like_score` is surfaced to the user.
- [ ] "Deleted Posts" (admin-only, Chronicle's Actions section) sits under the "New" `h3`
      subgroup in the left nav, but doesn't really belong there. CLAUDE.md's own left-nav
      convention already says a link that doesn't fit any bucket should stay loose directly
      under its `.left-nav-h2`, ungrouped, rather than forced into "New" — the implementation
      doesn't match that documented intent yet.
- [ ] Reorder the columns in the Filter Blog Posts view (`app/views/blog_posts/filter.html.erb`)
      — current order flagged as wrong during testing; correct order not yet specified.
