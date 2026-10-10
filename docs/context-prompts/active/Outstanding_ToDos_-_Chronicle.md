# Outstanding ToDos — Chronicle (Blog Posts)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Chronicle. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] The "Likes" → "Reactions" label rename (`docs/context-prompts/archive/Update_Feature_-_Likes.md`)
      is still incomplete in Filter Blog Posts (`app/views/blog_posts/filter.html.erb`), which
      calls the column "Smiles" (header and `filter_sort_link("smiles")`). Browse's cards were
      fixed on 2026-10-10 (now "Reactions:"). Apply the same name there.
- [ ] "Deleted Posts" (admin-only, Chronicle's Actions section) sits under the "New" `h3`
      subgroup in the left nav, but doesn't really belong there. CLAUDE.md's own left-nav
      convention already says a link that doesn't fit any bucket should stay loose directly
      under its `.left-nav-h2`, ungrouped, rather than forced into "New" — the implementation
      doesn't match that documented intent yet.
- [ ] Reorder the columns in the Filter Blog Posts view (`app/views/blog_posts/filter.html.erb`)
      — current order flagged as wrong during testing; correct order not yet specified.
- [ ] N+1: Filter Blog Posts loads each post's hero image one query at a time
      (Bullet: `BlogPost => [:blog_image_attachment]`, from
      `app/controllers/concerns/blog_post_filterable.rb:14`). Add `.with_attached_blog_image`
      to the filtered relation; Browse got the same fix on 2026-10-11.
- [ ] N+1: Filter Blog Posts results table loads each author's profile image one query at a time
      (Bullet: `User => [:profile_image_attachment]`, from
      `app/views/blog_posts/filter.html.erb:135`). Eager-load
      `user: { profile_image_attachment: :blob }` in the same relation.
