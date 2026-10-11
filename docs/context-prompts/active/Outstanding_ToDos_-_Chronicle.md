# Outstanding ToDos — Chronicle (Blog Posts)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Chronicle. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] Both js: true examples in `spec/features/blog_posts/create_blog_post_spec.rb` ("Adds a
      confirmed contact as a co-author via the shuttle", "Round-trips content between the Raw
      and Formatted tabs") are `xit`-skipped: the New Blog Post page's JS fails on CI only,
      never locally. Skipping the first just moved the failure to the second. Shuttle: page
      stays on `/blog-posts/new` after Save, even with a 10s wait. Round-trip: Raw panel never
      appears after clicking the Raw tab. Both await the `convert_format` fetch in
      `blog_post_editor_controller.js`. Next step: unskip one; `spec/support/failure_artifacts.rb`
      will put a screenshot/HTML/console log in CI's "screenshots" artifact.
      **Same flake now hits Edit Blog Post (2026-10-11), not yet skipped:** on PR
      `feature/browse-blog-posts-update`, CI failed `spec/features/blog_posts/edit_blog_post_spec.rb:206`
      ("Never removes the primary author's own row even if the shuttle is emptied out"): still on
      `/blog-posts/<slug>/edit` after "Update Blog Post". A local run hit the same symptom once on
      `:102` ("Removes an existing co-author via the shuttle"), then passed 3/3. Local console log
      was clean (favicon 404 only). So it's not CI-only, and `js_click` alone didn't fix the create
      shuttle spec, which points at the editor's submit flow (`handleSubmit` →
      `convert_format` fetch → `requestSubmit()`), not a lost click. Next step: get that CI run's
      "screenshots" artifact for the `:206` example and fix all four specs together in their own PR.
      **CI artifact for `:206` (checked 2026-10-11):** console clean (favicon 404 only); Quill
      loaded and seeded with the body; Category pre-selected; form had no `aria-busy`, so no
      Turbo submission was in flight. So the submit stalled before `requestSubmit()`: either the
      `convert_format` fetch never resolved (wait: 10 didn't help on Create, so it hangs rather
      than being slow), or the submit event never fired. Next: extend
      `spec/support/failure_artifacts.rb` to also dump `performance.getEntriesByType("resource")`
      (was `convert_format` requested, did it finish?) plus an in-page trace of whether
      `handleSubmit` ran, so the next CI failure says which.
      **Now `xit`-skipped too:** `:206` failed 3/3 CI runs on that branch (same example each
      time; CI runs in fixed order) but passed a full local `spec/features` run. It passed CI on
      main for PR #80, so something on that branch makes it deterministic on CI's slower runner.
      Only candidate found in the branch diff is the factory now always giving a post a
      Category (and the form's new `required` Category select), but the select was valid in
      the CI snapshot. Unskip all three once the extra logging is in.
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
