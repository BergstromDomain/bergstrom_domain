# Outstanding ToDos — Core

Cross-cutting inconsistencies, cleanup items, and follow-ups noticed during testing or
refactoring that aren't tied to one specific sub-app — see the per-app
`Outstanding_ToDos_-_<App>.md` docs for those. A new one of those gets created for each new
app as it ships.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] Missing eager loading (N+1 queries): Bullet (dev only, `config/environments/development.rb`)
      has now pinned down the known cases, logged in the per-app docs: 2 in
      `Outstanding_ToDos_-_Chronicle.md`, 1 in `Outstanding_ToDos_-_Occasions.md`. Fix them
      together in one small `perf` PR. Cross-app follow-up: consider enabling Bullet in the test
      env (`Bullet.raise = true`) so new N+1s fail specs instead of only showing up in the dev log.
      This matters more as more apps (Cookbook next) reuse the shared filter/browse patterns.
