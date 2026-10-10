# Outstanding ToDos — Occasions (Event Tracker)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Occasions. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] N+1: the People/Events filter loads each Event's people one query at a time
      (Bullet: `Event => [:people]`, from
      `app/controllers/concerns/people_events_filterable.rb:45`). Add `.includes(:people)` to
      the Event relation it iterates.
