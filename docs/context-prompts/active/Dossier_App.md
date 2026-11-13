# TASK
* Plan the development of a professional portfolio / CV master-data app to be integrated into
  BergstromDomain. (The companion career track — Bridge CV, LinkedIn, job search — lives in the
  git-ignored `docs/private/Career_Track.md`; this repo is public.)
* The app should be named **Dossier** and added to 'TopNav >> Apps', sorted alphabetically
  among existing apps (Chronicle, Cookbook, Dossier, Occasions, …).
* Outline the main development blocks for the app before writing any code.
* **Confirmation gate:** before starting a new development block, summarise what you know so far
  (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open
  design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor),
  the four-section spec structure (Happy / Negative / Alternative / Edge), the
  `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec
  pre-push chain. Flag it explicitly if this app needs an exception to any of these.

> **How to use this doc offline:** every question has an ID (e.g. `Q-C3`) and an empty `A:` line.
> Answer inline — one word is fine ("yes", "B", "skip for v1"). Questions marked ⭐ block the first
> block of work; everything else can wait. Unanswered questions are carried forward, not guessed.

---

# PART 2 — DOSSIER APP

# DECISIONS FROM REVIEW (2026-10-22)
Answers below are folded into the sections that follow; this is the summary.
* **Order:** Bridge CV → LinkedIn → Dossier app. All blocks are expected to be done before the
  site is published, so there is no separate MVP milestone (`Q-D21`).
* **Two-level employment model** (`Q-D5` + `Q-D15`): **Engagement** (employer/agency, employment
  type, Position = job title, dates) › **Assignment** (client, Role, dates, location, remote).
  Achievements attach to Assignments. A permanent job gets one Assignment automatically with
  client = employer, so stats and achievements work the same everywhere.
  * Years at an employer = Engagement span; years at a client = union of its Assignments.
  * Bench time = Engagement span not covered by Assignments; contractor gaps = time between
    Engagements.
* **Industry** lives on Organisation (one per client), not on Engagement (`Q-D19`). Organisations
  are shared across users (`Q-D4`).
* **Reference data** (admin-managed tables, narrow pages): Organisation, Industry, Role,
  Employment Type, Location, Skill Category, Credential Type (`Q-D9`). Seed CSVs in
  `docs/reference-data/dossier/`.
* **Voice** (`Q-D6` = B): one terse text stored everywhere. Only the Profile summary allows
  optional explicit per-voice versions. Third person needs a name/pronoun setting on Profile. AI
  generation of voices is Phase 2.
* **No text overrides** in CV Variants — wording edits go into master data (`Q-D7`).
* **No export snapshots** (`Q-D8`): no `CvExport` model, no Export History. Export = generate and
  download (`Q-D14`). Snapshots + old application folders are a future enhancement.
* **Templates** (`Q-D17`): private CV style first. Uploading a consultancy's own .docx template
  (with merge placeholders added in Word) is its own block after Variants — this favours export
  option B for Word.
* **Permissions:** Content Creator and above only (`Q-D2`); Admin read access same as other apps
  (`Q-D3`).
* **Public portfolio page** shows the full CV but **hides phone, email and address** — a contact
  link only (`Q-D20`).
* **Years display:** under 1 year "N months", otherwise "N+ years"; calendar overlap only, no FTE
  weighting (`Q-D11`).
* **Soft-delete retention:** 30 days, matching Recipes' `DELETION_RETENTION_PERIOD` (`Q-D12`).
* **Dates:** store exact dates when known; every generated CV shows month precision (`Q-D18`).
* English only (`Q-D16`). Icon `briefcase-business` (`Q-D1`). Commit prefix `Dossier` (`Q-D13`).
* **Tech Stack** (added 2026-10-24): every Assignment has a mandatory Tech Stack: Operating
  System(s), Project Methodology, System Under Test, Test Tools, Other Tools, Protocols. A section
  with no data must be marked **N/A** explicitly; it can't just be left empty. Mostly master data:
  CVs show it only when a variant switches it on. Items are Skills, so years per tool, OS,
  methodology or protocol come from the same calculation as other skills.

# DECISIONS FROM BLOCK 1 GATE (2026-10-30)
* **Namespace:** every Dossier model lives under `Dossier::` (tables `dossier_*`, URLs `/dossier/...`)
  so generic names (Role, Location, Skill…) never collide with core or future apps. A model can
  be promoted to the shared core later if another app needs it.
* **Who creates reference data:** Content Creators can *create* Organisations and Skills (needed
  for new employers/clients and Tech Stack tools on the fly); editing and deleting them, and all
  other reference data, is Admin only.
* **Permanent jobs:** Employment Type has a `permanent` checkbox; a permanent Engagement
  auto-creates its Assignment. Never inferred from the type's name.
* **Date precision:** every start/end date stores a date plus a `day`/`month` precision flag;
  pages show "15 Mar 2019" or "Mar 2019" accordingly, CVs always month.
* **Location:** separate `city` and `country`.
* **No icons** on Dossier reference data (the CSVs' Icon column is dropped).
* **One PR per block**, Block 1 built in steps 1a Reference data · 1b Profile · 1c Engagement +
  Assignment · 1d Tech Stack · 1e Timeline.
* Made during 1a (flagged, not asked):
  * Organisation has no stored `kind`: whether it is an employer, client or issuer follows from
    where it is used (one organisation can be all three). Organisation gains `abbreviation`
    (full name with abbreviation in headings, abbreviation in running text — as on the Bridge CV).
  * Reference-data descriptions are optional (the seed CSVs have none).
  * Reference-data list and show pages are public, like Cookbook's.

# DECISIONS FROM BLOCK 2 GATE (2026-10-30)
* **Scope:** Block 2 imports what exists after Block 1 — Profile, Organisations, Skills,
  Engagements, Assignments with their Tech Stack. Blocks 3 (Achievements) and 5 (Credentials) each
  extend the importer for their own data.
* **How:** a Dossier Import page — upload `master_cv.yaml`, dry-run preview, confirm. The file is
  read in memory and never stored.
* **Text:** Assignment summary = the `terse.summary`; verbatim originals stay in the YAML.
* **Re-import:** a matched record is skipped and listed as "already exists" — a re-import never
  overwrites edits made in the app. Matching: Organisation/Skill by name (Skill also by alias),
  Engagement by employer + start date, Assignment by Engagement + client + start date + Role (one
  client can have two Assignments starting the same month), Profile = one per user.
* **Ignored:** everything that isn't CV data (`vendors`, `notes_user_*`, `unconfirmed`, `src`,
  `linkedin*`, `conflicts`, `gaps`, `linkedin_alignment`, `bridge_cv`, …). Gaps come from the Timeline.
* **Private:** imported records are `restricted` (as Occasions' import does).
* **LinkedIn CSVs:** dropped — already merged into the master list.
* **Steps:** 2a Import service · 2b Preview/confirm page · 2c real import into dev, browser-checked.
* Made during 2a (flagged, not asked):
  * All-or-nothing: the preview is the real import run inside a rolled-back transaction, so the
    preview and the import can never disagree; any error blocks the whole import.
  * Reference data stays Admin-only: the importer creates missing Organisations and Skills for
    anyone, but Employment Types, Roles, Industries, Locations and Skill Categories only for an
    Admin. For anyone else an unknown Employment Type is an error; an unknown Role, Industry or
    Location is left empty, and an unknown Skill Category puts its Skills in "Uncategorised" —
    each with a warning.
  * Source tags on Skill and Skill Category names (`Provar (D)`, `Operating Systems (O)`) are
    stripped; a Skill listed under two categories keeps the first.
  * Profile: `terse_summary` → summary; the first `summaries` entry per voice → the first- and
    third-person versions. Citizenship and security clearance have no fields yet.
  * A permanent Engagement's auto-created Assignment takes the first listed Assignment's details.

# APP DESCRIPTION

Dossier is the **single source of truth** for a professional history. Nothing is ever deleted to
tailor a CV — tailoring is a *selection* over master data, saved as a named variant. Documents are
**generated**, never edited by hand as the master.

Problems it solves (from the brief):
| Problem | Dossier answer |
|---|---|
| Bullet points removed when tailoring a Word doc | Bullets live in master data; a CV Variant only includes/excludes/reorders them |
| Removed bullets lost in the next version | Master data is never edited by tailoring; variants are cheap copies; old variants kept |
| 1st person vs 3rd person vs terse versions | Each text block stores voice variants; export chooses the voice |
| One Word doc, many styles | Export pipeline with multiple templates/styles from the same data |
| Years of experience calculated by hand | Computed from dated engagements, sliced by employer, client, industry, role type, skill |
| Certificates scattered | Credential records with file attachments, issuer, dates, expiry |

Users should be able to:
* Maintain a **Profile** (name, headline, contact details, summaries in several voices)
* CRUD **Organisations** (employers *and* clients) and **Engagements** (positions/assignments with
  dates, role, industry, location)
* CRUD **Achievements** (the "bullet points") attached to engagements, with voice variants and tags
* CRUD **Skills** (with category, proficiency, and computed years of use)
* CRUD **Credentials** — degrees through short courses — with certificate uploads
* Create **CV Variants** — "Role X at Company Y": pick voice, style, sections, which
  achievements/skills to include, ordering, profile text override
* **Export** a variant to Word (and PDF) in multiple styles
* See **computed experience stats** (years by employer/client/industry/role type/skill)
* Optionally publish a **public portfolio page** (curated, public subset)

Ownership: single owner per dossier (one per user). Everything private by default.

Content format: plain text / short Markdown (bold, links) for bullets and summaries — **not**
WYSIWYG, because every block must render cleanly into Word, PDF, HTML and LinkedIn's plain-text
fields.

---

# DESIGN GUIDELINES
- Use the existing Authentication and Authorisation model (global roles: Visitor, App User, Content Creator, Admin, System Admin).
- Use the existing Data Classification model (Private / User's Circle / Public). **Default
  everything to Private (`restricted`)** — a CV holds phone numbers, addresses and possibly salary
  history. Public is opt-in per section for the portfolio page.
- The app should have its own landing page, consistent with other apps' landing pages
  (illustration prompt already exists: `Reference_App_Illustration_Prompts.md` › Dossier).
- The app should have a left nav bar, consistent with other apps (see Left Navbar block).
- Follow the established design system (warm off-white palette, terracotta accent, Lucide icons, `.show-panel` / `.resource-form` conventions). **Deliberate departure:** exported documents (Word/PDF) and possibly the public portfolio page have their *own* styles, independent of the site design.
- Buttons: use the existing `.btn`/`.btn-primary`/`.btn-secondary`/`.btn-danger`/`.btn-primary-action` classes — all resolve to the same blue, there is no color-coding by intent. Button text is always title case (every word capitalised, no exceptions for minor words). A button that navigates back to an index/parent page is labelled plain `Back`, not `Back to X`. See CLAUDE.md's "Buttons" note.
- All CSS lives in `app/assets/stylesheets/application.css` — it's the only stylesheet actually served (see CLAUDE.md's "Stylesheets" note before touching anything under `base/`/`layouts/`/`components/`).
- Page sizing (confirmed `Q-D10`): **normal** = Engagement, Assignment, Achievement, CV Variant,
  Credential, Profile; **reference** = Organisation, Industry, Role, Employment Type, Location,
  Skill, Skill Category, Credential Type.
- Use the existing global Toast component for Create/Update/Delete/Publish feedback (`Toastable` concern in `app/controllers/concerns/toastable.rb`, `shared/_toast` partial) — don't invent ad hoc flash messages. See the Toasts development block below.
- App icon candidates (all verified present in installed `lucide-rails` 0.7.4): `briefcase`,
  `briefcase-business`, `file-user`, `id-card`, `contact`. Credential-type icons: `graduation-cap`,
  `award`, `file-badge`. See `Q-D1`.
- Privacy: real CV data **never** goes into the repo (no seeds, fixtures, test data or screenshots
  with real phone/address). Test data uses fictional personas only. Import files are uploaded via
  the UI or read from a git-ignored path.
- Dates: engagements need month precision (Mar 2019 – Jun 2021); many old roles won't have exact
  days. Show as `MMM yyyy`, store as dates (first of month) + a precision flag if needed.

---

# PERMISSIONS MATRIX
*(Proposal — confirm in `Q-D2`. "Own" = the dossier owner.)*

| Action | Visitor | App User | Content Creator | Admin | Sys Admin |
|---|---|---|---|---|---|
| View public portfolio page | ✔ (if published) | ✔ | ✔ | ✔ | ✔ |
| View own dossier (all data) | | ✘ | ✔ | ✔ | ✔ |
| View another user's private dossier | | | | ✔ | ✔ |
| Create/edit own dossier data | | ✘ | ✔ | ✔ | ✔ |
| Create CV Variants / export | | ✘ | ✔ | ✔ | ✔ |
| Publish/unpublish own portfolio page | | | ✔ | ✔ | ✔ |
| CRUD shared reference data (Organisation, Industry, Role, Employment Type, Location, Skill Category, Credential Type) | | | | ✔ | ✔ |
| Restore soft-deleted records | | | | ✔ | ✔ |

Notes: confirmed in `Q-D2`/`Q-D3` — Content Creator and above; Admin read access follows the other
apps. Field-level encryption (Active Record Encryption) for phone/email is a possible later step.

---

# DATA MODEL
*(Draft — the core design decisions are the open questions below.)*

**Profile** (1 per user) — `user_id`, `display_name`, `headline`, `location`, `email`, `phone`,
`website_url`, `linkedin_url`, `github_url`, `classification`, pronoun/name setting for third-person
output, `summary` (terse) + optional per-voice summary versions (below). Phone/email/address are
never shown on the public portfolio page.

**Organisation** — `name`, `kind` (employer / client / both / education provider / issuer),
`industry_id` (one industry per organisation — `Q-D19`), `website_url`, `logo` (Active Storage),
`size_band`?, `notes`. Shared across all users (`Q-D4`).

**Engagement** (who employed or contracted you) — `profile_id`, `employer_id` (Organisation —
"Employer or Engaged via"), `employment_type_id`, `position_title` (job title at the employer or
agency), `start_on`, `end_on` (nil = current), `summary` (terse), `classification`.

**Assignment** (where the work was done) — `engagement_id`, `client_id` (Organisation; equals the
employer for a permanent job, created automatically), `role_id` (what you did for the client),
`start_on`, `end_on` (nil = current), `location_id`, `remote` flag, `summary` (terse),
`classification`, `position` (manual ordering tie-breaker), `system_under_test` (text, required;
"N/A" allowed), and one N/A flag per list section of the Tech Stack (`operating_systems_na`,
`methodologies_na`, `test_tools_na`, `other_tools_na`, `protocols_na`). Must fall within its
Engagement's dates. Bench time = Engagement span not covered by any Assignment.

**Tech Stack** (per Assignment, mandatory) — six sections:
| Section | Stored as | Examples |
|---|---|---|
| Operating System(s) | AssignmentSkill, `stack_slot: operating_system` | Windows (NT … 11), Linux (Ubuntu … Fedora), Android |
| Project Methodology | AssignmentSkill, `stack_slot: methodology` | Waterfall, Agile (Scrum, Kanban), Hybrid, Other |
| System Under Test | `assignments.system_under_test` text | "Salesforce CRM replacing the legacy BUILD system" |
| Test Tools | AssignmentSkill, `stack_slot: test_tool` | Jira, TestRail, Robot Framework, soapUI |
| Other Tools | AssignmentSkill, `stack_slot: other_tool` | Excel, VBA, SQL Server Management Studio |
| Protocols | AssignmentSkill, `stack_slot: protocol` | SIP, MGCP, MPEG, HL7, EMV, TR-069 |

Validation: each list section has at least one item **or** its `*_na` flag set (never both);
`system_under_test` is present. The slot belongs to the join, not the Skill, because the same
tool can be a test tool on one assignment and another tool elsewhere (Excel, Jira).
Assignment show page: a "Tech Stack" `.show-panel` listing the six sections, with N/A shown as
`N/A`.

**Achievement** (the bullet point) — `assignment_id` (nullable → general achievements),
`text` (terse), `impact_metric` (optional, e.g. "40% fewer defects"), `tags`/skills (many-to-many),
`importance` (1–5, used for default selection), `position`, `classification`, soft-deleted only.

**Voice handling** (`Q-D6` = B) — every text is stored once, in terse/implied form ("Have 25
years…", "Built X…"). Bullets render the same in every voice. Only the Profile summary allows
optional explicit versions per voice (`first_person` / `implied` / `third_person`), e.g. a
`ProfileSummary` row per voice. AI generation of the missing voices is Phase 2.

**Skill** — `name`, `skill_category_id`, aliases (e.g. "Selenium WebDriver" = "Selenium");
**AssignmentSkill** join with optional `primary` flag and `stack_slot` enum (`operating_system` /
`methodology` / `test_tool` / `other_tool` / `protocol`; nil = a skill used on the assignment that
isn't part of its Tech Stack). Unique on (`assignment_id`, `skill_id`, `stack_slot`). Years-of-use
derived from assignments. Methodologies and protocols are Skills too (Skill Categories such as
"Methodology" and "Protocols"), so "years in Scrum" works like "years with Jira".

**Credential** — `profile_id`, `credential_type` (degree / diploma / certification / course /
workshop / award), `title`, `issuer_id` (Organisation), `issued_on`, `expires_on`, `credential_id`,
`verification_url`, `hours`/`ects`?, `grade`?, `description`, attachments (`has_many_attached
:files` — PDF/images), `classification`, related skills.

**CvVariant** — `profile_id`, `name` ("QE Lead — Acme, Oct 2026"), `target_company`, `target_role`,
`job_description` (text, for later AI tailoring), `voice`, `style` (template key), `language`?,
`profile_summary_override`, section toggles/order (including a per-assignment "Tech Stack" line,
off by default), `based_on_id` (copied from another variant), `status`?.
**CvVariantItem** — `cv_variant_id`, polymorphic `item` (Engagement / Assignment / Achievement /
Skill / Credential), `included` boolean, `position`. No text overrides — wording edits go into
master data (`Q-D7`).

**No CvExport model** (`Q-D8`) — exports are generated and downloaded on demand. Snapshots ("what
did I send to company X?") are a future enhancement.

**Reference data** (admin-managed tables): Industry, Role (Test Manager, Test Lead, System
Tester…), EmploymentType (Permanent Employment, Temp, Consultant, Contractor), Location (City +
Country), SkillCategory, CredentialType (`Q-D9`). Seed lists in `docs/reference-data/dossier/`.

**Experience calculation** (service object, e.g. `ExperienceCalculator`):
* Years by X = **union** of date ranges per X (Assignment ranges for client/role/industry/skill;
  Engagement ranges for employer/employment type), not the sum — overlapping engagements (two
  part-time clients at once) must not double count.
* Open-ended (`end_on: nil`) counts up to today.
* Month granularity, calendar overlap only (no FTE weighting). Display: under 1 year "N months",
  otherwise "N+ years" (floor) — `Q-D11`.
* Bench time per consultancy Engagement; gaps between Engagements.
* Slices: employer, client, industry, role type, skill, employment type; "total career". Skill
  slices include Tech Stack items: per operating system, methodology, tool and protocol.
* Gaps (career breaks) shown on a timeline view — useful sanity check of the data itself.

**Soft delete / retention**: Achievements and Engagements soft-deleted, restorable (the whole
point is not losing bullets). Retention: 30 days, like Recipes (`Q-D12`).

**Toast labels**: Engagement → "`position_title` at `employer`"; Assignment → "`role` at `client`"; Achievement → first ~60 chars of text;
CvVariant → `name`; Credential → `title`; Organisation/Skill/etc. → `name`.

---

# EXPORT DESIGN (Word + multiple styles)

The core technical question. Options to evaluate in a spike (Block 7):

| Option | How styles work | Pros | Cons |
|---|---|---|---|
| **A. Pandoc** (HTML/Markdown → docx with `--reference-doc`) | One `reference.docx` per style, designed in Word | Styles authored in Word itself; PDF via same pipeline; mature | System binary dependency (Dockerfile/CI), less layout control (columns, sidebars) |
| **B. Template-in-Word gem** (e.g. `sablon` — mail-merge fields in a .docx) | Each style is a .docx template with merge fields/loops | WYSIWYG template design; very "Word-native" result | Gem maintenance status to check; loops/conditionals are fiddly |
| **C. Programmatic docx gem** (e.g. `caracal`) | Styles defined in Ruby | Pure Ruby, testable | Styling in code, maintenance status to check, tedious for rich layouts |
| **D. HTML + print CSS → PDF** (browser print, or headless Chrome) | One CSS file per style | Same tooling as the rest of the app; easiest to make beautiful | PDF only, not Word |

Likely answer: **D for PDF + A or B for Word**. Check each gem with bundler-audit and its last
release date before adopting — flag if a system dependency (pandoc, Chrome) has to be added to
deployment.

Tests: export specs can unzip the .docx and assert on `word/document.xml` content (included
bullets present, excluded bullets absent, correct voice) — keeps TDD meaningful for exports.

Other export targets worth designing for from the start (same data, different renderer):
* LinkedIn field view (copy per field, char-limit warnings)
* Public portfolio HTML page
* JSON Resume (open `jsonresume.org` schema) — portable, and some job sites accept it
* Plain text / Markdown (pasting into application forms)

---

# DEVELOPMENT BLOCKS
*(Order proposal — Blocks 0–3 + 7 make a usable MVP: data in, one Word/PDF out.)*

## Block 0 — App scaffold
* Add `Dossier` to `AppPermission` `app_name` enum, `.githooks/commit-msg` APPS list, `.gitmessage`
  (commit prefix name → `Q-D13`: `Dossier`? `Portfolio`?)
* TopNav › Apps entry (alphabetical), landing page with illustration, empty left nav
* Policy wiring + Permissions Matrix specs

## Block 1 — Profile + Reference data + Skills + Engagements + Assignments (with Tech Stack)
* Profile edit page (single record per user, create on first visit)
* Reference data CRUD (narrow pages): Organisation, Industry, Role, Employment Type, Location,
  Skill Category
* **Skill model** (moved here from Block 4 so the mandatory Tech Stack and the Block 2 import have
  it from the start): Skill CRUD (narrow pages) with category and aliases; `AssignmentSkill` join
  with `primary` flag and `stack_slot`
* Engagement CRUD (employer, employment type, position title, dates); a permanent job
  auto-creates one Assignment with client = employer
* Assignment CRUD under an Engagement (client, role, dates, location, remote)
* **Tech Stack** on the Assignment form and show page: five sections, each a multi-select of
  Skills (create-on-the-fly for new tool names) with an "N/A" checkbox, plus System Under Test as
  a text field. Validation: every section is filled or N/A. A permanent job's auto-created
  Assignment starts with every section N/A and System Under Test "N/A", so it saves; the Timeline
  flags Assignments whose Tech Stack is entirely N/A as incomplete
* **Timeline** (reverse chronological: Engagements with their Assignments nested; bench time and
  gaps visible)
* Validations: `end_on >= start_on`; Assignments within their Engagement's dates

## Block 2 — Import (seed from the Bridge CV master list — see `docs/private/Career_Track.md`)
* Import the merged master list (YAML/JSON, kept in the git-ignored `docs/private/`) → Profile, Organisations, Engagements,
  Achievements, Skills, Credentials
* Tech Stack per Assignment (master list `tech_stack:` → `system_under_test`, AssignmentSkills
  with `stack_slot`, `*_na` flags for "N/A" sections); unknown tool names become new Skills in an
  "Uncategorised" Skill Category for later tidy-up
* Optional: LinkedIn data-export CSVs (`Positions.csv`, `Education.csv`, `Certifications.csv`…)
* Dry-run preview → confirm → import; matched-by-name dedupe (same idea as Occasions'
  `ImportService`); everything imported as Private
* Import file never stored in the repo

## Block 3 — Achievements (bullet points) + voice variants
* CRUD achievements under an assignment; drag-to-reorder (or up/down buttons for v1)
* One terse text per achievement; per-voice versions only on the Profile summary
* Tags/skills, importance rating
* Soft delete + restore

### DECISIONS FROM BLOCK 3 GATE (2026-11-02)
* **Scope:** every Achievement belongs to one Assignment. General Achievements (no Assignment)
  wait for CV Variants.
* **Fields:** `text` (terse form), optional `impact`, `importance` 1–5 (default 3), `position`,
  `classification` (Private by default), Skills tagged through a join.
* **Skill tags:** Skills only, no free tags; typed as comma-separated text, unknown names become
  Skills in "Uncategorised" (as the Tech Stack does).
* **Ordering:** Up/Down buttons on the Assignment page in v1; drag and drop later.
* **Deleting:** soft delete; a Deleted Achievements page restores them; purged after 30 days
  (like Recipes).
* **Where shown:** the Assignment page lists its Achievements in order; My Career › Achievements
  lists them all, grouped by Engagement › Assignment. The Timeline is unchanged.
* **Navigation:** Actions › New › "Write An Achievement" (choose the Assignment first); "Add
  Achievement" button on the Assignment page.
* **Toast label:** the first ~60 characters of the text.
* **Import:** reads each Assignment's `terse.achievements` only; existing Assignments still get
  theirs; matched by Assignment + exact text and skipped if there; importance 3, YAML order.
* **Steps:** 3a model + Assignment page; 3b Achievements page, Write An Achievement,
  Deleted/Restore; 3c import + real dev import.

## Block 4 — Skill insights
*(The Skill model, CRUD and Tech Stack are built in Block 1.)*
* Computed years per skill shown on the Skill show page
* Skill show page lists the assignments using it, grouped by tech-stack slot, and the
  achievements tagged with it
* Merge duplicate Skills (e.g. two spellings created on the fly or by the import): repoint the
  joins, keep the old name as an alias

### DECISIONS FROM BLOCK 4 GATE (2026-11-03)
* **Done since Block 3:** System Under Test is a sixth Tech Stack Skill list (stack_slot
  `system_under_test`, its own N/A flag); Skill, Role, Organisation and Location pages list the
  signed-in user's own Assignments.
* **Using a Skill:** an Assignment uses a Skill when it's in its Tech Stack or tagged on one of its
  Achievements.
* **Whose data:** only the signed-in user's own. Skill pages stay public; a visitor sees the Skill
  and its description, nothing more.
* **Skill page:** a Your Experience panel (years, last used "Present"/"Oct 2015", Assignment
  count), then Your Assignments grouped by Tech Stack list (one Assignment can sit in two), then
  Your Achievements tagged with the Skill.
* **My Career › Skills:** every Skill the user has used, grouped by Skill Category, with years,
  last used and Assignment count, most years first.
* **Merge Skills:** Admin only. "Merge Into…" on the Skill page picks the Skill to keep, behind a
  confirm; Tech Stack and Achievement links move across (duplicates dropped), the old name and its
  aliases become aliases of the kept Skill, the old Skill is deleted; toast "X has been merged
  into Y".
* **Calculator:** `Dossier::ExperienceCalculator` with the Skill slice only; Block 6 adds the
  other slices. Reuses `Timeline.duration`.
* **Not now:** proficiency (wait for CV Variants); the `primary` flag on AssignmentSkill stays
  unused.
* **Deleted Engagements** (carried over from Block 3): a Deleted Engagements page with Restore
  and a 30-day purge job, like Achievements. A deleted Engagement hides its Assignments and their
  Achievements until restored.
* **Steps:** 4a calculator, Skill page, My Career › Skills; 4b Merge Skills; 4c Deleted
  Engagements.

## Block 4.5 — Personal Projects + Training

### DECISIONS FROM BLOCK 4.5 GATE (2026-11-04)
* **Personal Projects:** Employment Type gets a `personal` checkbox (like `permanent`); seed type
  "Personal Project". A personal Engagement has the user's own Organisation as employer and one
  Assignment per project, with its own Tech Stack and Achievements.
* **Years split:** experience is shown as professional and personal separately everywhere (Skill
  page, My Career › Skills gets a Personal column, sorted on professional years first). Personal
  time never adds to professional years.
* **Timeline:** personal Engagements are left out of gap and bench detection, so a hobby project
  never hides or fills a real gap; they still appear in the list, marked "Personal".
* **CVs (later):** personal projects get their own "Personal Projects" section, never Employment
  History.
* **Training is Block 5's Credential, started slim:** `Dossier::Credential` of type course with
  title, provider (Organisation), completed date with day/month precision, optional hours,
  Skills (comma-separated, like Achievements), description, classification (Private by default),
  optional `engagement_id` and `assignment_id` (the Assignment must belong to the Engagement); a
  course can also stand alone (bench, gaps).
* **Where Training shows:** a Training panel with Add Training on Engagement and Assignment pages,
  My Career › Training (newest first), Your Training on each Skill page, a Training count in My
  Career › Skills.
* **Training doesn't count towards years of experience** — it shows a Skill was learned, not used.
* **Company Specific:** a Skill Category the user creates for company-specific software and
  hardware (e.g. RPMD at Translink); no code.
* **Left for Block 5:** degrees/certifications, expiry and its warnings, certificate uploads,
  verification URLs.
* **Steps:** 4.5a Personal Projects; 4.5b Training.
* Made during 4.5b (flagged, not asked):
  * Training has a Started and a Completed date (reusing `Dossier::Dated`), not just a completed
    one: a multi-day course and an unfinished one ("Mar 2024 – in progress") both work, and a
    course within one month shows once. Block 5's expiry will be its own `expires_on`.
  * Provider is optional (a self-study course has none). Pages live at `/dossier/training`
    (`Dossier::CredentialsController`).
  * Deleting Training is a hard delete behind a confirm, with no Deleted page. Deleting an
    Assignment moves its Training up to the Engagement; a deleted Engagement hides its Training and
    the purge removes it.
  * Skills typed as text are shared with Achievements through `Dossier::SkillTags`; merging a
    Skill moves its Training links too.
* **Follow-up (2026-11-05):** Provider stays optional and uses the shared Organisations (e.g.
  LabVIEW by National Instruments). An Organisation page lists the signed-in user's own Training it
  provided (Your Training). Products and training providers such as LabVIEW / National Instruments
  belong on CVs; the "no vendor names" rule covers only the private `vendors` field (implementation
  partners) and is to be revisited with CV Variants.

## Block 5 — Credentials & certificates
* CRUD with credential type, issuer, dates, expiry, verification URL, file uploads (PDF/image)
* List grouped by type (Degrees › Certifications › Courses), expired ones flagged
* Expiry warning (state-based Warning toast on show page, like Chronicle drafts)
* Timeline bench/gap period pages (`/dossier/timeline/:from/:to`, added in Block 2) list the
  courses and credentials completed during that period — training often happens on the bench

### DECISIONS FROM BLOCK 5 GATE (2026-11-05)
* **Credential Type** is reference data (`Dossier::CredentialType`: name, position = group
  order, `training` flag). Seeds: Degree, Diploma, Certification, Course, Workshop, Award;
  Course and Workshop are training. Existing `course` rows move to Course. Training panels on
  Engagement/Assignment pages show training types only.
* **One list:** My Career › Credentials (`/dossier/credentials`), grouped by type in position
  order, expired ones flagged. It replaces My Career › Training.
* **New fields:** `expires_on` (optional, day/month precision), `credential_id` (licence/
  certificate number), `verification_url`. No grade/ECTS. Provider is labelled "Issued By".
* **Degree dates** reuse Started/Completed (Completed = awarded). A thesis goes in the degree's
  description.
* **Renewals:** one record per credential; a renewal updates `expires_on`, history goes in the
  description.
* **Expiry:** "Expired" badge on the list; Warning toast on the Show page when expired or
  expiring within 90 days.
* **Uploads:** several files per credential, PDF/JPEG/PNG, max 10 MB each, served only through a
  Policy-checked controller (owner/admin), whatever the record's classification. The public
  portfolio may later show title + verification link, never the file.
* **Period pages** list every credential completed in the period, not only training.
* **Import** from `master_cv.yaml`: `education` (MSc; SDSU exchange as a Course),
  `certifications`, `training`. Skipped: `linkedin_learning`, `education_linkedin`, and entries
  with year "?" (listed as skipped in the preview). `Dossier::Dated` gains a `year` precision for
  year-only entries.
* **Steps:** 5a types + fields + grouped Credentials page; 5b expiry; 5c uploads; 5d period
  pages; 5e import.

## Block 6 — Experience stats
* `ExperienceCalculator` service — union of ranges, slices by employer/client/industry/role
  type/skill
* Stats page (tables first; a chart/timeline later — reuse dataviz conventions)
* These numbers become insertable "highlights" in CV variants ("25 years in software testing,
  12 in DevOps-heavy environments")

### DECISIONS FROM BLOCK 6 GATE (2026-11-05)
* **One page, My Career › Experience:** a table per slice (Employers, Clients, Industries,
  Roles, Employment Types), each row with years, first–last dates and Assignment count, most
  years first. Skills stay on My Career › Skills (linked, not repeated).
* **Totals at the top:** Career (union of Engagements: bench counts, gaps don't), On Assignments
  (union of Assignments: bench left out), and Personal Projects on their own. Personal
  Engagements never feed the professional totals or slices.
* **No Role:** Assignments without a Role are listed under a "No Role" row, so the gap shows.
* **Reference-data pages:** Organisation (as employer and as client separately), Industry, Role
  and Employment Type pages show a "Your Experience" figure above Your Assignments. Visitors see
  no years.
* **Tables only;** a chart/visual timeline comes after Export. Highlight sentences wait for CV
  Variants (Block 8).
* **Who:** Content Creator and above, own data only.
* **Steps:** 6a calculator slices + totals; 6b Experience page + nav; 6c reference-data pages.

## Block 7 — Export spike, then Word/PDF export (MVP finish line)
* Spike: compare options A–D on one real-looking fictional CV; pick, document, then TDD
* Export the **full master CV** (no variants yet) in one style, Word + PDF

### DECISIONS FROM BLOCK 7 GATE (2026-11-05)
* **Spike = a write-up, not four prototypes.** Only the chosen route is built (on a fictional
  CV in the specs):
  * **A. Pandoc** — dropped: a new system binary for Docker, CI and every dev machine.
  * **B. `sablon`** / **C. `caracal`** — not needed: both add a gem whose upkeep would need
    checking, for output a small writer of our own can produce.
  * **D. HTML + print CSS → PDF** — chosen for PDF: `PdfRenderingService` (Ferrum + headless
    Chrome) already does this for Cookbook and Chronicle, and Chrome is already in CI.
  * **Word: our own small OOXML writer on `rubyzip`** (already in the Gemfile) — writes
    `word/document.xml` with named paragraph styles, the styles themselves in a
    `reference.docx`-style `styles.xml` that could later be restyled in Word. No new gem or
    binary; specs unzip the file and read `word/document.xml`. The same zip handling leads into
    Block 9 (filling placeholders in an uploaded .docx).
* **PDF footer:** `PdfRenderingService` takes a footer text; the CV's reads
  "<Display Name> · Page X of Y" instead of "BergstromDomain".
* **Contents, in order:** header (display name, headline, location, email, phone, website,
  LinkedIn, GitHub — the file is only ever downloaded by its owner); summary (first person,
  falling back to the terse summary); Experience (non-personal kept Engagements, newest first,
  each with its Assignments: client/project, role, dates, summary, Tech Stack and kept
  Achievements in position order, impact after the text); Personal Projects (personal
  Engagements, same layout); Skills grouped by Skill Category; then Credentials grouped by
  Credential Type in type order, all training types together as "Training", expired ones
  marked "(expired)". A permanent job's single synced Assignment folds into its Engagement
  (no repeated sub-heading). Vendor names never appear (the import never stores them).
* **One style, "Classic":** A4, single column, sans-serif (Calibri in Word, system font in the
  PDF), one dark slate accent — independent of the site's terracotta.
* **Download Master CV:** ACTIONS › Import & Export › Download Master CV opens a page with
  Download Word and Download PDF; the file downloads directly, no toast (`Q-D14`). Filename
  `<Display_Name>_CV_<YYYY-MM-DD>.docx|.pdf`. Content Creator and above, own data only; with no
  Profile the page asks for one first.
* **Steps:** 7a spike write-up + decisions; 7b `Dossier::CvDocument` (the CV's content, in
  order, no formatting); 7c HTML view + PDF download; 7d Word writer + Word download; 7e the
  Download Master CV page + nav, feature and eager-loading specs.

## Block 8 — CV Variants
* Create variant (from scratch or "Copy From" an existing variant)
* Selection UI: checkbox per engagement/achievement/skill/credential, ordering, voice, style,
  profile summary override
* Default selection rules (e.g. importance ≥ 3, last 10 years in detail)
* Export = generate and download; no stored history (`Q-D8`)

### DECISIONS FROM BLOCK 8 GATE (2026-11-06)
* **Models:** `Dossier::CvVariant` — user, name, target company, target role, job description
  (kept for later AI tailoring), voice (first person / implied / third person), style ("classic",
  the only one until Block 9b), summary override, Show Tech Stack (off by default), minimum
  importance (1–5, default 3), based on (the variant it was copied from).
  `Dossier::CvVariantItem` — one row per Engagement, Assignment, Achievement, Skill or Credential
  explicitly ticked or unticked. **No row = the default rules**, so new master data shows up in
  existing variants sensibly.
* **Summary:** the one text override a variant has (`Q-D7` otherwise stands); blank = the
  Profile summary in the variant's voice.
* **Default rules:** Engagements ending in the last 10 years in full, with their Assignments and
  the Achievements whose importance is at least the variant's minimum importance; older
  Engagements condensed (title, employer, dates only); Personal Projects off; Skills with
  professional years on, except the "Uncategorised" category; Degrees, Diplomas,
  Certifications and Awards on; Training and expired Credentials off. An explicit row always wins.
* **Edit Selection:** one plain form (no JavaScript) — a checkbox tree Engagement › Assignment ›
  Achievement (importance shown), then Skills by category and Credentials by type; Save and
  Reset To Defaults.
* **No reordering** in this block: jobs newest first, Achievements in master order.
* **Copy From** on New copies the settings and item rows of another of your variants.
* **Pages:** VIEWS › My CVs › CV Variants (index); ACTIONS › New › Create CV Variant. Show page
  with settings, what's included, Edit, Edit Selection, Download Word, Download PDF, Delete (hard
  delete with confirm). Normal data, full width. Content Creator and above, own only; Admin read.
* **Export:** `Dossier::CvDocument` takes an optional variant and filters through it; the
  renderers are unchanged (a condensed Engagement is a Meta line, no Assignments). Filename
  `<Display_Name>_CV_<Variant_Name>_<YYYY-MM-DD>.docx|.pdf`.
* **Later:** highlight sentences ("25+ years in software testing…") and reordering.
* **Steps:** 8a models + default rules; 8b variant pages + Copy From; 8c Edit Selection; 8d
  CvDocument filtering + variant downloads; 8e nav, feature and eager-loading specs.

## Block 9 — Upload CV Template (paused 2026-11-06 — see TODO)
* Upload a consultancy's own .docx template with merge placeholders added in Word (`Q-D17`);
  generate a variant into it

## Block 9b — Additional styles
* 2nd and 3rd style (e.g. "Modern Single Column", "Consultant Profile — third person with company
  branding area", "Compact 1-page")

## Block 10 — LinkedIn view
* Per-field formatted output with character counts/limits and Copy buttons

## Block 11 — Public portfolio page
* Public URL (e.g. `/dossier/niklas` or a custom slug), full CV (`Q-D20`) with phone/email/address hidden
  (contact link only), own styling,
  "Download CV (PDF)" from a chosen public variant

## Block 12 — Private Assignment details (last block before the app is complete)
Private to the author and Admins (the same check as certificate files); **never** on any export
— Word, PDF, LinkedIn view or public page (specs check this).
* **Colleagues:** one or several per Assignment — Name (mandatory), Position, Mobile, Email,
  LinkedIn, Comment (optional). A panel on the Assignment page.
* **Vendors** and **Customers:** optional, several each, as private links from an Assignment to
  Organisations (like Client). Not stored today — the import reads the master CV's `vendors:` and
  drops it; once this exists, a re-import fills them.
* **Example:** employed as a consultant at Deloitte (Engagement employer); Queensland Government
  (Client) runs project Alpha; PwC (Vendor) builds the software; Deloitte tests it; Telstra
  (Customer) buys the final product.

### DECISIONS FROM BLOCK 12 GATE (2026-11-06)
* **Colleagues per Assignment** (`Dossier::Colleague`): Name (required), Position, Mobile, Email
  (valid address), LinkedIn (http(s)), Comment. Someone you worked with twice is entered twice;
  a person-level record (or a link to Occasions' People) can come later. A "Colleagues" panel on
  the Assignment page lists them, with Edit and Delete per row; "Add A Colleague" opens its own
  small form. Hard delete with a confirm.
* **Vendors and Customers** (`Dossier::AssignmentPartner`): Assignment, kind (vendor / customer),
  Organisation and an optional Scope ("Built the Salesforce portal"); an Organisation once per
  kind per Assignment. A "Vendors & Customers" panel with "Add A Vendor" / "Add A Customer".
* **Organisation pages:** the owner sees "Your Assignments as Vendor" / "as Customer"; nobody
  else does. An Organisation linked as Vendor or Customer can't be deleted (like a Client).
* **Import:** each `vendors:` entry (name, project, scope) becomes a Vendor link — Organisation
  found by name or abbreviation or created; Scope "Project – scope" (or just the scope). A
  re-import adds missing Vendor links to existing Assignments (the one exception to "never
  changes existing records"); the preview lists them. Customers and Colleagues are manual only.
* **Never exported:** the Word/PDF generators never read these tables; specs fill all three in
  and check the master CV and a CV Variant (Word and PDF HTML) contain none of them. Blocks 10
  and 11 get the same checks. The panels show only to the owner and Admins, whatever the
  Assignment's classification.
* **Steps:** 12a Colleagues; 12b Vendors and Customers; 12c Organisation lists + delete
  protection; 12d vendors from the import; 12e never-exported and eager-loading specs.

### DECISIONS FROM BLOCK 12f GATE — Vendor and Customer Staff (2026-11-06)
* **Staff per Vendor/Customer link** (`Dossier::StaffMember`, belongs to an
  `AssignmentPartner`): the same fields and rules as Colleagues — Name (required), Position,
  Mobile, Email, LinkedIn, Comment. PwC's staff on Alpha are separate from PwC's staff on
  another Assignment. Colleague and StaffMember share a `Dossier::ContactDetails` concern and
  form/table partials so they can't drift apart.
* **Assignment page:** each Vendor or Customer in the Vendors & Customers panel lists its Staff
  underneath (Colleague-style rows with Edit and Delete) and has an "Add Staff" button opening
  "Add Staff Member" / "Edit Staff Member" pages; saving returns to the panel.
* **Access:** as Colleagues — seen only by the owner and Admins, changed by those who may update
  the Assignment; a Staff id from another link is a 404. Never on a CV (export spec extended).
* **Removing a Vendor/Customer** deletes its Staff; the confirm says how many.
* **Import:** an optional `staff:` list (name, position, mobile, email, linkedin, comment) in a
  `vendors:` entry; a re-import skips Staff whose name already exists on that Vendor link.
  Organisation pages don't show Staff.
* **Steps:** 12f refactor shared contact details; 12g Staff; 12h Staff from the import; 12i
  never-exported and eager-loading specs.

## Skill versions (2026-11-06, built on request)
* **Version Of:** a Skill can be a version of another, one level deep (`Dossier::Skill#parent` /
  `#versions`), e.g. Windows XP of Windows, Ubuntu of Linux. Each version stays its own Skill; an
  Assignment tags Windows for an unknown version, Windows XP when known. Set on the Skill form;
  the Skill page shows Version Of / Versions. Merging hands versions to the kept Skill; deleting
  a parent frees its versions.
* **CV display:** Skills and each Assignment's Tech Stack show a family as one entry —
  "Windows (XP, Vista)", versions in the order first used, the label being the name minus the
  parent's ("Ubuntu" when it doesn't start with it); the parent alone shows as "Windows". A CV
  Variant lists only its included versions.
* **Experience:** a version counts for its parent too (union of months); versions keep their own.
* **Parsing** (`Dossier::SkillNames`, Tech Stack, Achievement and Training skill lists): commas
  split only outside brackets; a Skill named with brackets ("Android (Eclair)") wins; otherwise
  "Name (a, b)" means versions a and b of Name — an existing version by label, else "Name a" by
  name/alias, else a new Uncategorised "Name a" under Name (never a version of a version).
* **Cleanup (manual, in the app):** merge "Windows (XP)" / "Windows (XP" into "Windows XP" etc.,
  delete the unused umbrella Skills, then set Version Of.

## Toasts — *reusable pattern*
* Implement `#to_toast_label` on every entity (see Data Model).
* Create/Update/Delete via `toast_created`/`toast_updated`/`toast_deleted`; Delete passes `info:`
  with the restore message for soft-deleted entities.
* Export: generate and download directly, no toast (`Q-D14`).
* Credential expiry is a state-based Warning toast.

## Left Navbar
* VIEWS
  * Dossier → landing page
  * My Career (`.left-nav-h3`) → Profile · Timeline (Engagements) · Achievements · Skills ·
    Credentials · Experience Stats
  * My CVs (`.left-nav-h3`) → CV Variants
  * Reference Data → Organisations · Industries · Roles · Employment Types · Locations ·
    Skill Categories · Credential Types
* ACTIONS
  * New → Create Engagement · Create Assignment · Write Achievement · Create Credential ·
    Create CV Variant · Add (reference data) — Create for entities, Write for text, Add for
    reference data, per convention
  * Import & Export → Import Dossier · Download Master CV
* DOCUMENTATION
  * How To → User Guide

---

# DEFINITION OF DONE (per block)
* For the first block: add the app name to `AppPermission`'s `app_name` enum and to
  `.githooks/commit-msg`'s `APPS` list / `.gitmessage` (Dossier is not reserved yet).
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* Permissions Matrix respected and covered by tests for each role
* Toasts fire via `Toastable`/`to_toast_label` for Create/Update/Delete/Publish, per the Toasts block — no ad hoc `notice:`/`alert:` left behind
* **No real personal CV data in commits, fixtures, specs, screenshots or EVIDENCE storyboards**
* Manually tested in the browser via `bin/dev`
* Confirmed with me before moving to the next block

---

# TODO
* **When working on CV Variants: print each Assignment's Tech Stack by Skill Category on the CV**
  (noted 2026-11-13). `Dossier::CvDocument` (~line 148) prints it by the internal stack lists
  (`TechStack::LABELS`): every Skill under Testing lands in "Test Tools", so QPT reads "Test Tools:
  Azure DevOps, Provar, Test Strategy" although Test Strategy is under Testing › Test
  Documentation. The Assignment page already groups by category (`Dossier::AssignmentTechStack`):
  consider the same grouping for the Word/PDF and master CV.
* **Future Enhancement: show each Soft Skill's description under its tick box** (requested
  2026-11-13), so it's clear what goes where. Each Soft Skill already has a description
  (`Dossier::SoftSkills::SKILLS`, editable on the Skill's Edit page), e.g. People Management:
  "Hiring, onboarding and running a team." and Leadership: "Setting direction, and leading people
  and teams towards it." Show it as a hint under each box on the Achievement and Contribution
  forms (`dossier/shared/_skill_fields`), or as an info tip.
* **Dev data clean-up (Niklas, on a large screen, before PROD)** — all done in the app with what
  exists today; no code needed. Planned 2026-11-06:
  1. **Merge and regroup Skills and Skill Categories:** Merge the import's broken bracket Skills
     (`Windows (XP` and `Windows (XP)` → `Windows XP`; `Windows (Vista)`, `Windows (NT)`;
     `Linux (Ubuntu` and `Red Hat)` → `Linux Ubuntu` / `Linux Red Hat`) and other duplicates;
     delete the unused umbrella Skills (`Windows (NT, XP, Vista, 8.1, 10, 11)`,
     `Linux (Ubuntu, Red Hat, Embedded, SUSE)`); set **Version Of** on versions (see Skill
     versions); move Uncategorised Skills into real Skill Categories (only categorised Skills are
     in a CV Variant's default selection).
  2. **Confirm all dates** on Engagements and Assignments (they drive years of experience,
     Timeline gaps and the CV).
  3. **Map courses to Assignments:** set the Assignment on each Training course taken during one.
  4. **Add Vendors and Customers** to Assignments if/when known (private).
  5. **Add Colleagues** (and Vendor/Customer Staff) when known (private).
  Then re-check the master CV and the CV Variants' Word/PDF downloads.
* **Upload CV Template (Block 9)** — paused 2026-11-06. Niklas is using the app as it is for a
  couple of weeks (reviewing and rewriting text, CV Variants, Classic Word/PDF). Revisit when a
  CV has to go into a specific consultancy's template; bring that template along, since it shows
  whether section placeholders are enough or loops are needed. Draft recommendations from the
  gate, not yet agreed:
  * **Placeholders:** text fields anywhere, headers/footers included — `{{name}}`,
    `{{headline}}`, `{{location}}`, `{{email}}`, `{{phone}}`, `{{website}}`, `{{linkedin}}`,
    `{{github}}`, `{{summary}}`, `{{target_role}}`, `{{target_company}}`, `{{date}}`; section
    fields alone on a paragraph — `{{experience}}`, `{{personal_projects}}`, `{{skills}}`,
    `{{credentials}}` — replaced by the whole section. No loops for now. Word splits typed text
    into several runs, so the filler must join a paragraph's runs before matching.
  * **Styles:** sections use Heading 1–3, List Bullet, Meta and Tech Stack, so the template's own
    definitions apply; missing styles get the Classic ones; bullets get their own numbering
    definition without touching the template's.
  * **`Dossier::CvTemplate`:** name, optional consultancy (Organisation), the .docx (≤ 5 MB),
    checked on upload (at least one known placeholder; unknown `{{…}}` rejected by name). Private
    to the owner and Admins.
  * **Variants:** Style lists Classic plus your templates; a template variant downloads Word only
    (PDF would need LibreOffice in Docker/CI) and offers the Classic PDF instead.
  * **Sample template:** a generated .docx with every placeholder and a note on each, to restyle
    in Word and upload back.
  * **Pages:** My CVs › CV Templates; New › Upload A CV Template; Show with the placeholders used,
    Download Original, Replace File, Edit, Delete (blocked while a variant uses it).
  * **Steps:** 9a template filler; 9b model + upload checks; 9c pages, sample template, nav;
    9d variant Style + Word download/PDF fallback; 9e eager-loading and permission specs.

---

# DEFERRED / PHASE 2
* **AI tailoring**: paste a job description into a CV Variant → Claude API suggests which
  achievements/skills to include, flags gaps, drafts the profile summary. Suggestions only — you
  accept/reject; never silently rewrites master data. (Great interview showcase.)
* **AI voice generation**: generate missing voice variants from the terse form (if `Q-D6` = store
  one + generate).
* **Dossier MCP server**: expose master data read-only to Claude Code/Desktop ("write me a cover
  letter for this ad using my dossier") — a direct demonstration of the AI-adoption skill set.
* Cover letters as their own entity linked to a CV Variant
* Job Leads / applications tracker (company, ad URL, variant sent, status, contacts) — or hand
  this to Docket
* LinkedIn posting via Share API; LinkedIn strategy doc
* Multi-language CVs (Swedish / English?) → `Q-D16`
* References/referees (very sensitive — private only, maybe never exported)
* Projects as a first-class entity (portfolio pieces like BergstromDomain itself, with links,
  screenshots, tech stack)
* Diff view: "what changed in master data since this variant was last exported"

---

# OPEN QUESTIONS — DOSSIER APP

* `Q-D1` ⭐ App icon: `briefcase`, `briefcase-business`, `file-user`, `id-card`, `contact`, or other?
  A:`briefcase-business`
* `Q-D2` ⭐ Who can use Dossier — only Content Creator and above (like creating content elsewhere),
  or any signed-in App User (a CV tool is useful to everyone)?
  A: Content Creator and above
* `Q-D3` Should Admin/Sys Admin be able to read other users' private dossiers? (Other apps allow
  admin read of restricted content; CV data may justify an exception.)
  A: Limited value of restricting read access for now. Unclear which persons will be Admins. I'm likely to be the only Sys Admin and I will have database access unless I start to encrypt the data. Keep same permissions as other apps for now
* `Q-D4` ⭐ Organisations: shared across all users (one "Consultancy A" record for everyone, like
  Event Types) or private per user? Shared = less duplication; private = no leaking that you
  worked somewhere.
  A: Shared - I dont see a need to hide where you have worked
* `Q-D5` ⭐ Consultancy model: Employment › Assignments as two levels (Consultancy A 2021–2024 ›
  Client A, Client B), or flat engagements each with an optional client?
  A: Client feels like the important part, if I worked there as a consultant or contractor is less relevant but want to be able to see how long I have worked for company Consultancy A. For consultant companies there will be "bench time" but for contractor roles there will be gaps between roles
* `Q-D6` ⭐ Voice variants: (A) store all three texts explicitly, (B) store one terse form and
  generate the others (rules or AI), (C) store terse + optional explicit overrides?
  A: If all 3 are stored, does that imply that for each new achievement, the user will have to write all 3? Based on that option B is best
* `Q-D7` Can a CV Variant override a bullet's text, or must all wording edits go into master data?
  (Overrides recreate the "lost edit" problem; forcing master edits keeps one truth but may add
  near-duplicate bullets.)
  A:Master for now. Future enhancement to identify a way to identify and clean up this data
* `Q-D8` Keep a snapshot/copy of every exported file (audit "what did I send to X"), or just
  regenerate on demand?
  A: From my early career, each job I applied for had a folder with a CV and coverletter. Most of the CVs were identical which is a waste. Many of the cover letters were the same as well with the exception of the address, date and jobtitle. Saving snapshot (and adding my old files for reference) can be moved to a future enhancement
* `Q-D9` Credential types: fixed enum (degree / certification / course / workshop / award) or
  admin-managed reference data?
  A: I'm familiar with my industry but it's possible that it's different for other industries. Lets do admin-managed reference data
* `Q-D10` Agree with the normal vs reference page-sizing split in Design Guidelines?
  A:Yes
* `Q-D11` Years display: "25+ years" (floor), "25.4 years", or "25 years 5 months"? Count years
  by calendar overlap only, or weight part-time engagements (FTE %)?
  A:Less than 1 year: [TBD] months, over 1 year: [TBD]+ years
* `Q-D12` Soft-delete retention for your own career data: forever, or N days like Chronicle?
  A:N days should be fine
* `Q-D13` ⭐ Commit prefix / technical app name: `Dossier`, `Portfolio`, or `Career`? (Existing
  pattern: technical name ≠ brand, e.g. `Recipes` → Cookbook.)
  A: Dossier
* `Q-D14` Export UX: direct file download, or generate → toast → download from Export History?
  A:Generate and download
* `Q-D15` Left-nav verbs: "Add Engagement / Write Achievement / Add Credential / Create CV Variant"
  OK? Better word than "Engagement" (Position? Role? Assignment?)
  A: 
  Engagement	| Employer or Engaged via	| Who employed or contracted you, plus the employment type
  Assignment	| Client			| Where the work was actually done
  Position	| Title				| Your job title at the employer or agency
  Role		| Role				| What you did for the client
* `Q-D16` CV languages: English only, or Swedish too (per-language text variants)?
  A: English only, for the last jobs in Sweden I used an English CV
* `Q-D17` Which Word styles do you need first? E.g. (1) modern private CV, (2) Consultancy A-style
  consultant profile, (3) Consultancy B-style consultant profile — do the consultancies require their
  own branded templates?
  A: Private CV style first; upload a consultancy's own .docx template later — see Decisions (Block 9).
* `Q-D18` Dates: is month precision enough for all roles? Any roles where you only know the year?
  A: Month precision on all generated CVs but store exact dates when known
* `Q-D19` Should "industry" be per engagement (from the client) or allow multiple per engagement
  (e.g. a fintech client in the government sector)?
  A: Make it simple with one industry per client (I might be forced to pick one dependent on the actual project)
* `Q-D20` Public portfolio page: v1 or Phase 2? What should it show — full CV, highlights only,
  projects?
  A: Full CV 
* `Q-D21` MVP scope check: is "Blocks 0–3 + 7" (data in, one master CV out) the right first
  milestone, or do you need Variants (Block 8) before Dossier is worth using?
  A: Likely to complete all blocks before Bergstrom domain gets published
