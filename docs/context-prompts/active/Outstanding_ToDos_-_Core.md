# Outstanding ToDos — Core

Cross-cutting inconsistencies, cleanup items, and follow-ups noticed during testing or
refactoring that aren't tied to one specific sub-app — see the per-app
`Outstanding_ToDos_-_<App>.md` docs for those. A new one of those gets created for each new
app as it ships.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] Audit for missing eager loading (N+1 queries) — flagged during testing; the exact
      controller/view location(s) weren't pinned down at the time, needs a proper pass (e.g.
      Bullet gem, or a manual review of `includes`/`preload` across list views) to find and fix.
