# Outstanding ToDos — Core

Cross-cutting inconsistencies, cleanup items, and follow-ups noticed during testing or
refactoring that aren't tied to one specific sub-app — see the per-app
`Outstanding_ToDos_-_<App>.md` docs for those. A new one of those gets created for each new
app as it ships.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] Consider enabling Bullet suite-wide in the test env (`Bullet.raise = true`) so any new N+1
      fails specs instead of only showing up in the dev log. For now only the pages in
      `spec/requests/eager_loading_spec.rb` are guarded, via `without_n_plus_one_queries`
      (`spec/support/bullet_helpers.rb`). Add new list pages there, especially as Cookbook
      reuses the shared filter/browse patterns.
