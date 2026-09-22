# TASK
* Capture ideas/requirements for the first PROD deployment of bergstromdomain.com as they come
  up, so nothing gets lost between now and when a deployment is actually attempted. This is a
  living scratchpad, not a finished plan — items get added, refined, or crossed off over time.

---

# KNOWN GAPS / TO DECIDE

## Infra & deploy
* `config/deploy.yml` (Kamal) is still the generated template — placeholder server IP
  (`192.168.0.1`), no real `proxy`/SSL block, no domain. `Dockerfile`/Kamal are currently unused
  (per `[[footer_feature_shipped]]` memory — `BuildInfoService` was built deploy-mechanism-agnostic
  because of this). Need: real host, domain, SSL termination (Kamal's built-in Let's Encrypt proxy
  vs. Cloudflare in front), registry to push images to.
* SQLite is the current adapter (see `volumes:` comment about "sqlite database files") — confirm
  this is the intended PROD datastore, or whether it should move to Postgres/MySQL before
  launch. If staying on SQLite, the Kamal `volumes:` persistent storage path needs to be backed
  up off-server (comment in `deploy.yml` already flags this).
* No CI/CD deploy step exists yet — GitHub Actions currently only runs tests/lint/security scans,
  not `bin/kamal deploy`.

## Storage
* `config/storage.yml`'s S3 block is commented out — Active Storage (profile images, blog/event
  images) currently implies local disk, which is fine under Kamal's persistent volume but is a
  single point of failure/backup gap. Decide: stay on the Kamal volume + external backup, or
  switch to S3/R2 before launch.

## Email
* SMTP config in `config/environments/production.rb` is commented out — no outbound email
  (password resets, notifications) will work in PROD until a provider (Postmark/SendGrid/SES/etc.)
  is chosen and credentials added.

## Secrets & credentials
* `RAILS_MASTER_KEY` is the only secret currently wired into `deploy.yml`. `db/seeds.rb` reads
  `admin_email`/`admin_password` from encrypted credentials for the one real (non-persona) admin
  account — confirm production credentials are set before first boot, since seeds are the only
  path that creates that account.
* Registry auth (`username`/`password` in `deploy.yml`) is still commented out — needed once a
  real registry (not `localhost:5555`) is chosen.

## Data / content
* `db/seeds.rb` currently creates the full named-persona cast (Pat Pending, Sue Suspended, the
  Metallica people/events, HP/LOTR/Star Wars/Jack Ryan franchises) — this is dev/test fixture
  data and must **not** run as-is against PROD. Need a PROD-safe seed path, or a documented
  manual bootstrap step instead.
* **Superseded/generalized 2026-09-22**: `docs/reference-data/` is now the master, maintained-
  during-development list of *all* reference/taxonomy data that needs to exist in PROD but isn't
  part of the app-user-facing seed data — currently Event Types, Blog Categories, and Social
  Media Platforms (the latter's actual logo image files included), one CSV per type grouped by
  app, with a README explaining the format and the maintain-then-deploy workflow. Blog
  Categories' entry there supersedes the standalone `[[Test_Data_-_Chronicle_Categories]]` doc as
  the source of truth for PROD deployment purposes (that doc stays as historical manual-testing
  context, just isn't the thing to work from anymore for this).
  * **Still open, decided informally in chat but not built**: whether this stays a manual runbook
    (an admin re-enters each row through the app's own Create forms — the only path that exists
    today) or gets a real bulk-import feature. If built, most reference types (Event Types, Blog
    Categories, and probably most future ones like Cookbook's Cuisines/Food Types) reduce to the
    same "unique name + a few scalar columns" shape and could share one generic
    find-or-create-by-name importer parameterized by model class + column mapping — matching what
    `ImportService` already does for `EventType` as a side effect of importing Events. Social
    Media Platform is the one genuine exception: its `logo` is an uploaded file, not a plain
    column, so it needs its own file-resolve-and-attach step regardless of whatever shared
    importer exists for the rest. Not yet designed further than this, deliberately — no code
    written.
* Confirm whether any of the current dev-only content (franchise people/events) should exist in
  PROD at all, even scoped to the real admin account, or whether PROD starts genuinely empty
  aside from reference data like Blog Categories.

## Auth / users
* Sign-up currently creates `pending` users (see `Roleable`/`User#status`) — confirm the
  approval workflow (`SystemAdmin::` namespace) is the intended gate for real public sign-ups,
  and that whoever holds the real admin/system_admin account in PROD is committed to actually
  reviewing that queue.

## Monitoring / ops
* No error tracking (Sentry/Honeybadger/etc.), uptime monitoring, or log aggregation configured
  yet. Kamal's `logs` alias only tails the container directly.
* `VERSION` file is currently pinned at `1.0.0` and is meant to start incrementing after the
  first PROD deployment (per `[[footer_feature_shipped]]`) — remember to bump the versioning
  process once real deploys start happening.

## Domain / DNS
* No real domain is wired up anywhere in config yet (bergstromdomain.com is the intended
  domain per `CLAUDE.md`, but `deploy.yml`'s `proxy.host` is commented out).

---

# POST-DEPLOYMENT STEPS IDENTIFIED SO FAR
*(Steps intended to run once, after the app is live in PROD, rather than being part of the
deploy itself or the dev seed data.)*
* **Re-create all reference data** — see `docs/reference-data/README.md` for the current full
  list (Event Types, Blog Categories, Social Media Platforms) and how to work through it; entered
  by hand through each resource's own admin Create form, one row at a time, since no bulk-import
  path exists for these types yet (see the open question logged under Data / content above).
  `BlogCategory`/`EventType` have no creator/author column at all, so "authored by the System
  Admin" is a procedural convention for whoever runs this step, not something the schema
  enforces or stores.

---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while planning PROD deployment.)*
* Target host/provider for Kamal (VPS? which one?) — not yet decided.
* SQLite vs. a server database for PROD — not yet decided.
* Email provider — not yet decided.
