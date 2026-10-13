# Outstanding ToDos — Chronicle (Blog Posts)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Chronicle. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] The "Likes" → "Reactions" label rename (`docs/context-prompts/archive/Update_Feature_-_Likes.md`)
      is still incomplete in Filter Blog Posts (`app/views/blog_posts/filter.html.erb`), which
      calls the column "Smiles" (header and `filter_sort_link("smiles")`). Browse's cards were
      fixed on 2026-10-10 (now "Reactions:"). Apply the same name there, including the
      `smiles` SQL field in `BlogPostFilter::FIELD_SCHEMA` (Cookbook's equivalent is
      `reactions`), and update `docs/user-guide/chronicle/02_reading_blog_posts.md` to match.
- [ ] "Deleted Posts" (admin-only, Chronicle's Actions section) sits under the "New" `h3`
      subgroup in the left nav, but doesn't really belong there. CLAUDE.md's own left-nav
      convention already says a link that doesn't fit any bucket should stay loose directly
      under its `.left-nav-h2`, ungrouped, rather than forced into "New" — the implementation
      doesn't match that documented intent yet.
- [ ] Reorder the columns in the Filter Blog Posts view (`app/views/blog_posts/filter.html.erb`)
      — current order flagged as wrong during testing; correct order not yet specified.
- [ ] My Published Posts / My Draft Posts only show posts where you're the main author:
      `BlogPostFilterable` turns `author_id` into the primary author's name, matched against
      `BlogPostFilter`'s `author` (`post.user`). Posts you co-wrote are missing. Match any of
      the post's authors.
- [ ] Chronicle Settings' Start Page option says "My Unpublished Posts"
      (`app/views/settings/chronicle_settings.html.erb`) where the left nav says "My Draft
      Posts". Use one name.
- [ ] The Chronicle landing page (`app/views/pages/chronicle.html.erb`, "Write and Format")
      promises videos, tables and embedded documents, which the editor can't do yet. Reword
      it, or keep it once those content-format gaps are closed.
- [ ] Editing a published post turns it back into a draft (`BlogPostsController#update`
      merges `published_at: nil`), but editing a published Cookbook recipe keeps it published.
      Decide which behaviour both apps should have; the User Guides currently describe each
      as it is.
