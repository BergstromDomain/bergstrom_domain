# Outstanding ToDos — Occasions (Event Tracker)

Inconsistencies, cleanup items, and follow-ups noticed during testing or refactoring, specific
to Occasions. See `Outstanding_ToDos_-_Core.md` for cross-app items.

Add an item as soon as it's spotted, however small. Delete the line once it's actually fixed —
no "resolved" section here, git history already has that record.

## Open

- [ ] **Privacy leak:** a person's page (`app/views/people/show.html.erb`, `@person.events`)
      lists every event they're in, whatever the event's Visibility, and the People list's
      Event Types icons (`app/views/people/index.html.erb`, `person.events`) do the same. A
      guest viewing an Unrestricted person sees the titles of their Restricted events. Scope
      both to the viewer's visible events (and leave out muted ones, if wanted). Found
      2026-10-13 while writing the User Guide.
- [ ] **Privacy leak:** the People dropdown on Create/Edit Event (`app/views/events/_form.html.erb`,
      `Person.order(:last_name, :first_name)`) lists every person, including other users'
      Restricted people. Limit it to the people the current user can see.
- [ ] An event on 29 February with no year is rejected as "Date is not valid" —
      `Event#date_must_be_valid` checks a yearless date against 2001, which isn't a leap year.
      Check against a leap year instead.
- [ ] Download → Import doesn't round-trip: `ExportService` writes an empty Event date for an
      event without a year, but `ImportService` needs `-MM-DD`; and a person with no events
      downloads as a row with empty event columns, which fails on import with "Unknown event
      type ''". Export yearless dates as `-MM-DD`, and let import create a person-only row.
- [ ] Filter People and Events (`PeopleEventsFilterable#date_range_for`,
      `PersonEventFilter.event_date`): Event Date's This Week/Month/Year only run up to today
      and compare the full date including the year, so an event without a year never matches
      and a birthday later this month doesn't show under This Month. Decide whether these
      should match on day/month (the anniversary) across the whole period.
- [ ] Filter People and Events: the Classification filter and `classification` SQL field use
      the person's Visibility, not the event's (`PersonEventFilter.attributes_for`). Decide
      whether it should be the event's, or offer both.
