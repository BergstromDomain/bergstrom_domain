# TASK
* Placeholder only — capture the idea and open questions now so nothing gets lost, but this is
  explicitly **not** being designed or built yet. Several more features/apps are planned before
  the first PROD deployment (see `Deployment_-_PROD_Readiness.md`), and DORA metrics are
  meaningless without real deployments happening — there's nothing to measure yet.
* Revisit once `Deployment_-_PROD_Readiness.md`'s "No CI/CD deploy step exists yet" gap is
  closed (i.e. once `bin/kamal deploy` or equivalent is actually wired into CI/CD) — that's the
  real prerequisite, not a specific calendar date.

---

# FEATURE DESCRIPTION
* The four DORA (DevOps Research and Assessment) metrics, industry-standard measures of software
  delivery performance:
  1. **Deployment Frequency** — how often code successfully ships to PROD.
  2. **Lead Time for Changes** — time from commit merged to that commit running in PROD.
  3. **Change Failure Rate** — % of deployments that cause a failure in PROD (rollback, hotfix,
     incident).
  4. **Time to Restore Service (MTTR)** — how long a PROD incident takes to resolve, once one
     happens.
* Goal: understand delivery health over time for this solo project the same deliberate way the
  RSpec test-results dashboard (`Feature_-_Test_Result_Dashboard.md`) tracks test-suite health —
  not because DORA is normally aimed at teams, but because the same "visualize a trend instead of
  just gut-feeling it" principle applies.

---

# OPEN QUESTIONS
*(Running log — nothing below is decided, this whole doc is pre-design.)*

* **Should these be displayed in Grafana?** Leaning yes, but worth confirming for real once this
  is actually scoped:
  * **For reuse**: the Grafana Cloud account + push pipeline built for
    `Feature_-_Test_Result_Dashboard.md` (Blocks 6a–6d — `RspecMetrics::Pusher`'s Line Protocol
    HTTP push pattern) already exists and works. Deployment Frequency and Lead Time for Changes
    are both derivable from GitHub data (commit timestamps, a deploy step's completion
    timestamp) and could push into the *same* Grafana Cloud stack via the same mechanism,
    rather than standing up a second, separate DORA-specific tool.
  * **Against/complication**: Change Failure Rate and MTTR need something Deployment Frequency
    and Lead Time don't — a way to mark a specific deployment as *failed* and track when an
    incident started/resolved. That likely depends on error tracking / incident monitoring,
    which `Deployment_-_PROD_Readiness.md` also lists as not set up yet ("No error tracking
    (Sentry/Honeybadger/etc.), uptime monitoring, or log aggregation configured yet"). So this
    might end up being two-phase: Deployment Frequency + Lead Time first (only needs CI/CD +
    git data), Change Failure Rate + MTTR later (needs monitoring infra to exist first).
* Where does "a deployment happened" actually get recorded once `bin/kamal deploy` exists — a
  CI/CD step pushing a metric directly (mirroring the RSpec pipeline), a git tag, Kamal's own
  release tracking, something else?
* What counts as a "failure" for Change Failure Rate on a solo project with no formal incident
  process — a manual marker, a rollback command, an error-tracking alert crossing some
  threshold?
* Does this want its own Grafana dashboard, or a couple of extra panels added to the existing
  test-results one? No opinion yet — depends on how it's actually scoped when the time comes.

---

# DEFERRED / PHASE 2
* Everything — this entire feature is deferred until PROD deployment automation exists.
