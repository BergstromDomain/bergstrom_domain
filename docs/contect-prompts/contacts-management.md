# Context Prompt — Contacts Management and Filtered Views

This is the first feature built with Claude Code instead of a
per-post context-prompt-in-chat workflow. `CLAUDE.md` already covers
the stack, commands, architecture, named test personas, and spec
conventions — don't repeat any of that here. This file is scoped to
what's specific to *this* feature.

## Roadmap context

App Management and Deploy have both been deliberately postponed —
App Management until several apps are actually deployed and per-app
permission tuning matters, Deploy until a few more apps exist, freeing
up time to get comfortable with Claude Code first. This feature,
**Contacts Management and Filtered Views**, is the next thing being
built, and the first one built primarily through Claude Code sessions
rather than a single long chat.

## What already exists — don't rebuild this

The `Contact` model (`app/models/contact.rb`) and the `contacts`
classification value (`Classifiable` concern) already exist and are
fully functional at the data layer:

```ruby
class Contact < ApplicationRecord
  belongs_to :user
  belongs_to :contact, class_name: "User"

  enum :status, { pending: "pending", confirmed: "confirmed" }, validate: true

  validates :contact_id,
    uniqueness: { scope: :user_id, message: "has already been added" },
    numericality: { other_than: :user_id, message: "cannot be yourself" }, if: -> { user_id.present? }

  scope :confirmed, -> { where(status: "confirmed") }

  def self.confirmed_between?(user, other) ... end
  def self.confirmed_contact_ids_for(user) ... end
end
```

`Classifiable#visible_to_users` already calls
`Contact.confirmed_contact_ids_for(user)` to resolve the `contacts`
classification's visibility — a record classified `contacts` is
already correctly visible to confirmed contacts today. **What's
missing is entirely at the UI/controller layer**: there is no
`ContactsController`, no routes, no views, and therefore no way for a
user to actually create a `Contact` row, confirm one, or remove one.
The `pending`/`confirmed` status enum already anticipated a
request/accept flow; it's just never been wired to anything a user
can click.

**Naming collision to be aware of**: `spec/features/pages/contact_spec.rb`
and the `contact_path` route are the existing static "Contact Me" page
(Nik's own contact info — Post #1-era static page), completely
unrelated to the `Contact` model. Don't confuse the two, and pick
naming for new controller/views/specs that won't collide (e.g.
`ContactsController`/`contacts_path` for the plural resource is fine
and doesn't collide with the existing singular `contact_path`, but
double-check route helper names don't clash before generating).

## What's new: the settings-page left nav

`SettingsController` currently does **not** include the `Navigable`
concern at all — visiting `/settings` today renders with no left nav.
`Navigable#left_nav_section_for` only maps `events`/`event_types`/
`people`/`pages` controllers to the `:event_tracker` section
(`app/views/layouts/_left_nav.html.erb`). Giving Settings its own left
nav, in the same visual pattern as Event Tracker's, is new work:

- Add a `:settings` (or similar) case in `left_nav_section_for` for
  the `settings` and (new) `contacts` controllers.
- Add a corresponding section in `_left_nav.html.erb`, matching the
  existing `.left-nav-section`/`.left-nav-h2`/`.left-nav-h3`/
  `.left-nav-link` structure and `data-testid` convention already
  used for the Event Tracker section — this is additive, not a
  redesign.
- Two links in this new section per Nik's description: **User
  details** (existing `settings_path`) and **Contacts Management**
  (new).

## What's new: Contacts Management itself

A user should be able to, from a new Contacts Management page:
- Send a connection request to another user (creates a `Contact` row,
  `status: pending`).
- See and act on incoming pending requests (accept → `confirmed`,
  reject → presumably destroy the row rather than leave it in a
  rejected limbo state — confirm this rather than assuming, since the
  schema has no `rejected` status today, only `pending`/`confirmed`).
- Remove an existing confirmed contact (destroy the row).

Worth deciding explicitly, not silently: **is a `Contact` row directed
or symmetric once confirmed?** The schema has `user_id` (requester)
and `contact_id` (recipient) — once `confirmed`, does removal by
either party fully sever the connection (destroy the one row,
regardless of who initiated it), or does the model need to
distinguish "I removed them" from "they removed me"? Given
`confirmed_between?` already checks both directions symmetrically,
the simplest and most consistent answer is almost certainly "either
party destroys the one row and it's gone for both" — but say so
explicitly in the PR/commit rather than leaving it implicit.

## What's new: filtering — the harder, less-specified half

Two distinct filter mechanisms were asked for on Event Tracker list
views:

1. **Classification-based filtering** — straightforward: a filter
   control (checkboxes, similar in spirit to the by-letter tab bar or
   by-month tabs already in the app) for `restricted`/`contacts`/
   `unrestricted`, scoped to whatever the user can already see per
   `Policy`/`Classifiable` — this filter narrows visibility further,
   it never grants access beyond what's already permitted.
2. **A follow/unfollow mechanism** — genuinely underspecified as
   written, and this is the part to resolve with Claude Code in Plan
   Mode before writing code, not assume silently:

   The example in Nik's own scoping (Adam/Beth/Charlie/Diana/Eric,
   with per-example categories like "Family birthdays," "Friends
   birthdays," "Music albums: 80's music," "Marvel movies") lines up
   very naturally with **`EventType`** — the app already has an
   icon-based categorization primitive on every `Event`
   (`app/models/event_type.rb`), and `EventsController#index` already
   partially supports filtering by a specific type
   (`@selected_type_id`, from `params[:event_type_id]`). Follow/unfollow
   at the `EventType` level is very likely what's intended, and would
   extend an existing mechanism rather than invent a new one.

   But this needs confirming explicitly before building it, because
   the alternative readings aren't unreasonable either:
   - Follow/unfollow a specific **Person** (e.g. unfollow one specific
     friend's birthday reminders specifically, not the "Friends
     birthdays" category as a whole)?
   - Follow/unfollow an individual **Event** (one-off, not category-wide)?
   - The **interest levels** (High/Medium/Low) in the example — are
     these meant to be an actual three-tier feature, or just narrative
     motivation for *why* filtering matters? Nothing in the two
     concrete requirements ("classification filter" + "follow/unfollow")
     obviously needs three tiers rather than a plain boolean
     follow/unfollow — confirm scope before building a tiering system
     that isn't actually asked for.

   Recommended first step in the Claude Code session: **use Plan
   Mode and ask Claude to propose a data model for follow/unfollow**
   (most likely a new join table, e.g. `event_type_follows` —
   `user_id` + `event_type_id` + maybe a boolean or the presence/
   absence of the row itself standing in for followed/muted) **before
   any code is written**, explicitly stating the granularity question
   above so the plan addresses it rather than picking one silently.

## Scope of "Event Tracker list views"

Confirm which views the filters need to reach — the description says
"Event Tracker list Views" without pinning down whether that means:
- Just the plain `events#index` list,
- The three calendar views from Post #17 (`by_day`/`by_week`/`by_month`),
- Or all of the above.

Given the calendar views already carry their own view-specific state
(selected day/week/month) alongside `@selected_type_id`, extending
classification/follow filters to all three is more work than just the
index — worth scoping explicitly in the plan rather than discovering
the gap after `events#index` alone is done.

## Suggested Claude Code workflow for this feature

1. `/plan` (or "use plan mode") — read `Contact`, `Classifiable`,
   `EventType`, `EventsController#index`, and `_left_nav.html.erb`
   first, then propose an approach that explicitly answers the three
   open questions above (rejected-request handling, follow/unfollow
   granularity, which list views are in scope) rather than picking
   silently.
2. Build in the same increments the blog posts used: model/migration
   first (Red → Green on a model spec) → controller → view → feature
   spec, per logical chunk, committing at each stage.
3. Reuse the existing named test personas and Metallica `Person`
   fixtures for contact-request scenarios (e.g. Uno User sends a
   request, Ulrika User accepts it) rather than inventing new ones.
4. Run the pre-push sequence after each logical chunk, not just at
   the end.
5. Full `rspec` + `/review` once functionally complete, same as the
   collation post — get real numbers, don't trust "should be green."
