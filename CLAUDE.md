# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The Rails app behind bergstromdomain.com — a personal platform intended to host several
sub-apps under one auth/permission system. Only **Event_Tracker** (people, events, event
types) is implemented so far; **Blog_Posts**, **Recipes**, and **Photo_Album** exist today
only as enum values / stub routes (`app_name` in `AppPermission`, `pages#blog_posts`,
`pages#event_tracker`) reserved for future apps. Development is documented as a blog series
(`docs/blog/`) written in strict Red → Green → Refactor TDD style — keep that workflow in
mind when asked to add features: write/adjust the spec first.

## Commands

```bash
bin/setup                 # bundle install + db:prepare + starts bin/dev (add --skip-server to skip)
bin/dev                   # start Rails dev server

bin/rails db:prepare      # create/migrate dev db
RAILS_ENV=test bin/rails db:prepare

bundle exec rspec                                          # full suite
bundle exec rspec spec/models/event_spec.rb                 # single file
bundle exec rspec spec/models/event_spec.rb:42               # single example at line
bundle exec rspec --exclude-pattern "spec/features/**/*_spec.rb"  # everything but system tests
bundle exec rspec spec/features/                             # system tests only (Capybara + Chrome)
COVERAGE=1 bundle exec rspec                                  # enforce SimpleCov 90% minimum

bin/rubocop                # lint (rubocop-rails-omakase base + .rubocop_todo.yml)
bin/rubocop -A              # autocorrect
bin/brakeman --no-pager -i config/brakeman.ignore   # static security scan (config/brakeman.ignore holds reviewed false positives)
bundle exec bundler-audit check --update   # gem vulnerability scan (.bundler-audit.yml ignores)
bin/importmap-audit         # JS dependency vulnerability scan (config/importmap-audit.yml ignores —
                            # bin/importmap audit itself has no ignore mechanism, unlike bundler-audit)
```

CI (`.github/workflows/`) runs all of the above (brakeman, bundler-audit, importmap audit,
rubocop, rspec non-feature specs, rspec feature specs) plus a commit-message linter on every
PR — see Commit conventions below.

## Architecture

**Auth**: Custom, not Devise. `Session` records (not just cookies) back authentication;
`Current` (`ActiveSupport::CurrentAttributes`) holds the request-scoped session/user. The
`Authentication` concern (`app/controllers/concerns/authentication.rb`) is included in
`ApplicationController` and requires auth by default — use
`allow_unauthenticated_access only: %i[...]` per controller to opt specific actions out (see
`EventsController` for the public/authenticated split on index vs. mutating actions).

**Roles vs. classification — two independent axes of access control:**
- `Roleable` concern (on `User`): `role` enum — `app_user`, `content_creator`, `admin`,
  `system_admin`. Governs *what a user is allowed to do in general*.
- `Classifiable` concern (on `Event`, `Person`): `classification` enum — `restricted`,
  `contacts`, `unrestricted`. Governs *who can see a specific record*: unrestricted is
  public, contacts is visible to the owner's confirmed contacts (`Contact.confirmed_between?`),
  restricted is owner/admin only.
- `Policy` (`app/models/policy.rb`) is the single authorization gate — `can_read?/create?/update?/delete?`.
  It layers in `AppPermission`, a per-user-per-app override (`app_name` enum:
  `event_tracker`/`blog_posts`/`recipes`/`photo_albums`) that lets an individual user's
  create/update/delete rights be granted or revoked independently of their global role —
  this is how a `content_creator` could be restricted to one sub-app. Controllers instantiate
  `Policy.new(current_user, resource_or_app_symbol)` (a bare app symbol like `:event_tracker`
  is used for `new`/`create` before an instance exists) and redirect on a failed check rather
  than raising.
- `system_admin` role additionally gates the `SystemAdmin::` namespace
  (`SystemAdmin::BaseController#require_system_admin!`), used for approving/suspending/rejecting
  user registrations and changing roles — separate from the `Policy`/`AppPermission` system.

**Domain model**: `Person` and `Event` are joined many-to-many through `EventPerson`;
destroying the last `EventPerson` for an `Event` destroys the `Event` itself (see
`EventPerson#destroy_event_if_no_people_remain` — an event with no people is not a valid
state). `Event` belongs to `EventType` (icon-based categorization using Lucide icon names,
validated against `LucideRails::IconProvider`). Both `Person` and `Event` use `friendly_id`
(`:slugged, :history`) — look up records with `.friendly.find`, not `.find`.

`Person#full_name` is a virtual attribute (`first_name middle_name last_name` joined), not a
column, and uniqueness is checked case-insensitively across it in Ruby
(`full_name_must_be_unique`) rather than in SQL — be aware of the O(n) scan (`Person.all.find`)
this implies at scale. The A–Z browse feature buckets people by `last_name` (falling back to
`first_name`), including three extra Swedish letters (Å, Ä, Ö) beyond A–Z
(`Person::BUCKET_LETTERS`); person name sorting/collation uses a Swedish collation added via
migration (`db/migrate/*_add_swedish_collation_to_people_names.rb`) rather than app-level
Ruby sorting.

**Import/export**: `ExportService`/`ImportService`/`ImportTemplateService`
(`app/services/`) round-trip people+events through a fixed CSV column layout
(`ExportService::HEADERS`). Export scope is classification-based (`scopes` array of symbols
like `:unrestricted, :contacts`); import always creates records as `restricted` and matches
existing people/events/event-types by case-insensitive name to avoid duplicates.

**View conventions**: Ruby files use a `# path/to/file.rb` comment on their first line
(matches this repo's existing style throughout `app/models/`, `app/controllers/`, etc.) —
keep doing that. `.html.erb` files should **not** get the equivalent `<%# path/to/file.html.erb %>`
comment on their first line — it breaks ERB syntax highlighting in VS Code. Existing view
files that already have this comment don't need to be retrofitted, but don't add it to new
ones.

**Stylesheets**: `app/assets/stylesheets/application.css` is the *only* stylesheet actually
served (Propshaft doesn't process `@import`, and `app/views/layouts/application.html.erb`
links only `application`) — its own header comment says as much. The `base/`, `layouts/`,
`components/` subdirectories and `people.css` are dead/unused leftovers with their own
(sometimes divergent) copies of the same rules — e.g. `base/variables.css` defines an unused
`--color-accent: #4f46e5` that is shadowed by `application.css`'s own `--color-accent:
#b07d56`. Don't edit those files expecting it to change anything; all layout/nav/button CSS
work happens directly in `application.css`.

**Buttons**: every `.btn-*` class (`.btn-primary`, `.btn-secondary`, `.btn-danger`,
`.btn-primary-action`) resolves to the same blue (`--color-primary`/`--color-primary-dark` in
`application.css`) — there is no more color-coding by intent (e.g. red for destructive
actions). The class names are kept only as semantic hooks for future per-class styling, not
because they currently look different. Button label text is always title case (every word
capitalised, no exceptions for minor words like "and"/"by"). A button that navigates back to
an index/parent page is labelled plain `Back` (not `Back to X`) — see `.btn-secondary` links
across `app/views/*/show.html.erb`.

**Left nav structure** (`app/views/layouts/_left_nav.html.erb`): every app section follows the
same two-level header shape — `.left-nav-h2` (top-level, "H1" in the design doc's own
shorthand) wraps one or more `.left-nav-h3` groups ("H2" in that shorthand):

```
VIEWS (h2)
  [App Name] (h3)         → link to the app's own landing page
  [App-specific group(s)] (h3)  → e.g. Occasions: "Events", "People"; Chronicle: "Blog Posts"
  My [Items] (h3)         → "My Published X" / "My Draft X" links, signed-in users only — omit if N/A
  Reference Data (h3)     → shared header name across apps; link text is app-specific
ACTIONS (h2, content-creator-and-above only)
  New (h3)                → the app's Create/Write/Add links — Write for long-form content
                             (Blog Post, Recipe), Create for entities (Person, Event), Add for
                             reference data (Event Type)
  Import & Export (h3)    → nested here, not a standalone top-level section; omit if the app
                             has nothing to import/export yet (e.g. Chronicle currently)
DOCUMENTATION (h2)
  How To (h3)
    User Guide             → stub link until written
```

**Page sizing** (New/Show/Edit): every resource is either "normal" data (Person, Event, Blog
Post) or "reference" data (Event Type, Social Media Platform, Blog Category — the same set
grouped under a left nav's "Reference Data" header, above). Normal-data pages render full
width; reference-data pages render at a narrower, centered width, consistently across their
New, Show, and Edit pages:
- New/Edit forms: `.resource-form` alone is the narrow (560px, centered) default, used by
  reference-data resources. Add `.resource-form--wide` for normal-data resources (`class:
  "resource-form resource-form--wide"` on the `form_with` call) to go full width.
- Show pages: full width is the default (no wrapper needed) — normal-data Show pages render
  their `.show-panel`s unwrapped. Reference-data Show pages wrap their `.show-panel`s in a
  `.page-content--half` div to match the same resource's form width.

A link that doesn't fit any bucket (e.g. Chronicle's admin-only "Deleted Posts") stays loose
directly under its `.left-nav-h2`, ungrouped, rather than being forced into "New" or another
ill-fitting `.left-nav-h3`.

**Testing**: RSpec + FactoryBot + Capybara (system specs use real Chrome, see CI's
`google-chrome-stable` install) + shoulda-matchers + database_cleaner (transactional by
default, truncation for `js: true` specs). SimpleCov enforces 90% minimum coverage when
`COVERAGE=1` is set. `spec/rails_helper.rb` is the entry point for Rails specs (loaded via
`.rspec`'s `--require spec_helper`, which in turn needs `rails_helper` required explicitly at
the top of Rails-aware spec files per convention).

**Named test personas** (`spec/support/authentication_helpers.rb`) — a consistent cast used
across all feature specs, verbatim from the file's header comment:

```
Gary Guest               — unauthenticated visitor, no account, no let declaration needed
Pat Pending              — create(:user)                      status: "pending"
Sue Suspended            — create(:user)                      status: "suspended"
Uno User                 — create(:user)                      status: "active"      app_user role
Ulrika User              — create(:user)                      status: "active"      app_user role
Charlie Content Creator  — create(:user, :content_creator)    status: "active"      content_creator role
Chris Content Creator    — create(:user, :content_creator)    status: "active"      content_creator role
Curtis Content Creator   — create(:user, :content_creator)    status: "active"      content_creator role
Adam Admin               — create(:user, :admin)              status: "active"      admin role
Sam SysAdmin             — create(:user, :system_admin)       status: "active"      system_admin role
```

All factory users default to `status: :active` and `password: "password123"`. Gary Guest is
the only persona who is not signed in — just visit the path directly (no `let` declaration
needed).

**Four-section spec structure**: model and service specs (see `spec/models/event_spec.rb`,
`spec/models/person_spec.rb`, `spec/models/user_spec.rb`,
`spec/services/export_service_spec.rb`, `spec/services/import_service_spec.rb`) are organized
into exactly four sections, in this order:

1. `Happy path`
2. `Negative path`
3. `Alternative path`
4. `Edge cases`

New specs should follow the same structure and ordering as these existing files.

## Manual testing

Automated coverage (rspec, rubocop, brakeman, bundler-audit) is necessary but not
sufficient. Before opening a PR for a new feature, manually exercise it end-to-end via
`bin/dev` in a real browser — automated specs verify code correctness, not that the feature
actually works and feels right to use.

## Commit conventions

Commit messages (and thus PR titles containing them) are enforced by both a local
`.githooks/commit-msg` hook and CI (`.github/workflows` commit-lint job) with the exact
format:

```
<App>:\t<type>:\t<description (min 10 chars)>
```

Apps: `Main`, `Event_Tracker`, `Blog_Posts`, `Recipes`, `Photo_Album` (use the app the change
belongs to; `Main` for cross-cutting/infra work). Types: `feat`, `fix`, `refactor`, `test`,
`chore`, `docs`, `style`, `perf`, `build`, `revert`. The hook regex (`[[:space:]]+`) between
sections accepts a tab or one-or-more plain spaces; `.gitmessage` and the hook's help text
model it as a tab, but actual history uses a single space (e.g. `Main: fix: pre-push hook no
longer fails on an empty commit range`) — match that, not the template. Run `git config
commit.template .gitmessage` / ensure `core.hooksPath` points at `.githooks` if commits are
being rejected unexpectedly.

**Merging a branch back to `main`**: this repo has no auto-merge — pushing a branch only
creates it on the remote. `main` only advances once a PR for that branch is opened and
merged **in the GitHub UI** (by the repo owner); there is no CLI/API step that accomplishes
this from within a session. After push, wait for that merge to happen before running `git
checkout main && git pull` — pulling beforehand just leaves local `main` unchanged and stale.
This matters most when starting a new branch that needs to build on work just pushed: branch
from `main` only after confirming (via `git pull`, or `git log --oneline -3 main` showing the
expected merge commit) that the merge has actually landed, rather than assuming it has.
