---
name: new-app-scaffold
description: Starts a brand-new sub-app on bergstromdomain.com in two phases. Phase 1 fills the app's planning doc (docs/context-prompts/active/<Name>_App.md, from App_-_TEMPLATE.md) with a concrete description, permissions matrix, data model, development blocks and numbered open questions, then stops at the confirmation gate. Phase 2 builds Block 0, the scaffold every app needs before its first model, and verifies it with a checker script. Block 0 wires the commit prefix, AppPermission/UserAppSetting/GuidePage enums, Policy, the route, the landing page with its hero image, TopNav Apps entry (alphabetical), Navigable, a left nav skeleton, specs and CLAUDE.md. Use this whenever the user wants to plan, start, stub, scaffold or "do Block 0" of a new app such as Docket, Gallery, Logbook, Meeple, Relay, Songbook, Tasting, Verse or Voyage, or asks to "fill out" or "flesh out" a *_App.md doc, add an app to the Apps menu, or reserve a new app name, even if they don't name this skill. Not for features inside an existing app (use the Feature template), and not for Block 1+ work on an app that already has its landing page.
---

# New App Scaffold

Every sub-app on this site (Occasions, Chronicle, Cookbook, Dossier, and the nine still in the pipeline) starts the same way. First there is a planning doc the user can work through, often offline on a flight. Then comes Block 0, which touches about fifteen files spread across commit tooling, enums, routing, navigation and docs. Missing one of them is easy and only shows up later: an app missing from the commit-lint list rejects its first real commit, and a missing `Navigable` branch makes the landing page show Occasions' left nav. This skill makes both steps complete and repeatable.

There are two phases, run at different times:

1. **Plan:** fill the app's planning doc and stop at the confirmation gate. Nothing in `app/`, `spec/`, `config/` or `db/` changes.
2. **Block 0:** after the user has answered the blocking questions, build the scaffold test-first and verify it with `scripts/check_scaffold.rb`.

Work out the phase from the situation. A doc that is still the raw template, or a request like "plan the Logbook app", is Phase 1. "Questions answered, start Block 0" is Phase 2. If the user asks for both at once ("set up Meeple"), do Phase 1 and stop at the gate. Block 0 bakes in decisions (technical name, icon, who sees the Actions section) that are expensive to rename later.

## Names: decide these first

Every app has four names. Getting them consistent is most of Block 0.

| Name | Example (Dossier) | Example (Cookbook) | Example (Occasions) | Used for |
|---|---|---|---|---|
| **Brand** | Dossier | Cookbook | Occasions | What users see: Apps menu, page title, left nav, `DISPLAY_NAMES` |
| **Commit prefix** | `Dossier` | `Recipes` | `Event_Tracker` | `<App>: <type>: <desc>`, the APPS lists, `.gitmessage` |
| **Enum key** | `dossier` | `recipes` | `event_tracker` | `AppPermission`, `UserAppSetting`, `GuidePage`, `Policy`, `@left_nav_section` |
| **Route / page** | `dossier` | `cookbook` | `event_tracker` | `get "dossier"`, `pages#dossier`, `dossier_path`, `<route>-hero.png` |

The older apps have technical names that differ from their brands. The newest one, Dossier, uses the brand everywhere, which is simpler. Propose that by default (brand `Docket` → prefix `Docket`, key `docket`, route `docket`), but it is the user's call, so ask.

## Phase 1: fill the planning doc

### 1. Gather what already exists

Read these before writing anything. The user has usually said more about the app than the request does.

- `docs/context-prompts/active/<Name>_App.md`: often still the untouched 202-line template. Sometimes it already holds the user's own notes in an older free-form layout (see `Docket_App.md` and `Gallery_App.md`). **Keep every line the user wrote.** Move it into the template's sections rather than replacing it, and don't silently drop their ideas.
- `docs/context-prompts/templates/App_-_TEMPLATE.md`: the structure to follow.
- `docs/context-prompts/active/Reference_App_Illustration_Prompts.md`: has a section per planned app describing what it is about, for the landing-page illustration.
- `docs/reference-data/<app>/`: the hero image `<Brand>_Landingpage_Wide.png`, plus any CSVs or logos for reference data.
- The most recently built app's archived or active doc (`archive/Cookbook_App.md`, `active/Dossier_App.md`): shows the level of detail that worked, and the decisions that recur.
- `CLAUDE.md`: left nav shape, page sizing, buttons, Write/Create/Add verbs, toasts.

### 2. Fill every template section

Replace every `[ITEM]`, `[APP NAME]` and `*(Fill in…)*` placeholder with something concrete:

- **TASK:** the app's name and one-line purpose.
- **APP DESCRIPTION:** what users do, the ownership model (single owner or co-owners), content format, metadata, browse and filter dimensions.
- **DESIGN GUIDELINES:** keep the template's shared bullets. Add:
  - app-specific ones (mobile use for Logbook, privacy for Dossier, and so on);
  - **app icon candidates checked against the installed lucide-rails, and against icons the site already uses** (`ruby .claude/skills/new-app-scaffold/scripts/check_scaffold.rb --icons a,b,c`). The script reports each name as missing, free, or already used (with file:line). Prefer free icons. An icon already used for a button or a resource inside another app (e.g. `list-checks` on Dossier's Edit Selection) makes the left nav ambiguous, so mention the clash in the icon question;
  - each resource classified as normal or reference data.
- **PERMISSIONS MATRIX:** fill in every cell, marking uncertain ones `?` and raising a question for each.
- **DATA MODEL:** entities, key fields, relationships, soft delete, `to_toast_label` for each entity. Keep schema decisions here rather than hidden in UI blocks.
- **DEVELOPMENT BLOCKS:** number them, starting with **Block 0: App scaffold** (see `references/block0-checklist.md` for its contents). Adapt or delete the template's Chronicle examples (Reactions, Comments, Browsing) per app. Don't keep them by default. Propose an MVP line ("Blocks 0–3 make a usable first version").
- **Left Navbar:** the app's real groups and links, using the Write/Create/Add verbs.
- **DEFERRED / PHASE 2:** good ideas that are out of scope.
- **OPEN QUESTIONS:** see step 3.

Ideas you add are proposals. Phrase them as proposals ("Proposal:", "Likely answer:") so the user can tell them apart from decisions they've made. Don't present invented facts about the user's life or data as true.

### 3. Write questions the user can answer offline

The user often works through these docs without internet, so every question must stand on its own:

- Give each question an ID with a per-doc prefix (`Q-D1` for Data, `Q-P2` for Permissions…), followed by an empty `A:` line underneath.
- Make each one answerable in a word or a letter. Label choices **Option A / Option B / Option C** (never bare `A)`/`B)`, which reads like the `A:` answer line), with the trade-off of each.
- Give every question a **Default:** line naming the option you'd pick and why, in one sentence. A blank `A:` then means "take the default", so the user only has to write where they disagree. Say this in the how-to note.
- Mark with ⭐ the questions that block Block 0: technical name and commit prefix, app icon, who may create content (Actions section visibility), and whether the landing page is public. Everything else can wait for its own block.
- **Keep the list short.** The ⭐ questions plus about 15 more is plenty for a first pass. A question only belongs in the list if its answer changes what gets built; if you'd build the same thing either way, state the assumption in the doc as a "Proposal:" instead. Put lower-priority questions under a `## Can wait` heading at the end of the list, grouped by the block they affect.
- Write each question, with its `A:` line, **once**: under `# OPEN QUESTIONS` at the end, grouped by section. In the body, point to it by ID ("see Q-D3") next to the text it concerns. Two copies of a question mean two places to answer and a chance they disagree.
- Start the doc with a short note on how to use it: answer under OPEN QUESTIONS, ⭐ = needed before Block 0, blank `A:` = accept the default.

### 4. Stop at the gate

Show the user a short summary in plain chat text, not the multiple-choice question tool (the user prefers plain text for these gates). The summary covers:

- what the app is in one sentence;
- the proposed blocks and MVP line;
- the ⭐ questions;
- anything you assumed.

Don't touch application code in this phase, and don't commit. The user's `docs/` tree often has uncommitted reorganisation work on `main`, so leave staging to them.

## Phase 2: build Block 0

### 1. Confirm and branch

- Restate the ⭐ answers you are building on (names, icon, public landing page, Actions visibility). A blank ⭐ answer means the doc's default; say which default you're taking. If a ⭐ question has no answer and no default, ask for that one only.
- Run `check_scaffold.rb --icons <icon>` on the chosen icon. If it's already used elsewhere, say where in your restatement and carry on; the user chose it.
- If another app's Block 0 is in flight on another branch, warn the user: both touch the same lines (APPS regexes, the enum lists, the Apps menu, `CLAUDE.md`), so the second PR to merge will need a rebase. Check with `git branch -a --list '*scaffold*' '*block-0*'`.
- Check `git status`, then create a feature branch (`feature/<route>-app-scaffold`) **before** the first commit. Never commit to `main`.
- Leave unrelated changes in the working tree out of your commits. Stage files by name, never `git add -A` or `git add .`.

### 2. Commit-tooling first (its own commit)

Add the commit prefix to `.githooks/commit-msg` (both the `APPS=` regex and the help echo), `.githooks/pre-push`, `.github/workflows/commit-lint.yml` and `.gitmessage`. Commit this alone as `Main: build: add <Prefix> to the commit-message app list`. Until it lands, every `<Prefix>:` commit is rejected by the hook, which is why it goes first.

If a `<Prefix>:` commit is still rejected after the tooling commit, check `git config core.hooksPath`. In a git worktree it can point at the main checkout's `.githooks`, which doesn't have the new prefix yet. Don't reach for `--no-verify`, which skips validation altogether. Commit with `git -c core.hooksPath=.githooks commit …` instead. That still runs the hook, just the branch's own up-to-date copy, so the message is still validated. If that command is blocked, leave the files staged and give the user that exact command to run, saying why.

### 3. Red: write the specs

Follow `references/block0-checklist.md`, which lists every touch point with the Dossier code to copy. Write the failing specs first, in the four-section structure with the named personas:

- the new landing page spec, `spec/features/pages/<route>_spec.rb`;
- additions to `top_nav_spec`, `policy_spec`, `app_permission_spec`, `user_app_setting_spec`, `guide_page_spec` and `spec/requests/left_nav_spec.rb`.

Run them and confirm they fail for the right reason (missing route or enum value), not because of a typo.

If the `test-case-design` skill is available, use its Phase 1 for the persona matrix. Block 0 is small, so a compact matrix (Gary sees the page, Uno sees no Actions, Charlie reaches it, Adam and Sam the same) is enough.

### 4. Green: wire it up

Work through the checklist. Points that are easy to get wrong:

- **Alphabetical Apps menu:** insert the new entry in brand order, and update the "Lists the apps alphabetically" spec to the full new list.
- **Hero image:** copy `docs/reference-data/<app>/<Brand>_Landingpage_Wide.png` to `app/assets/images/<route>-hero.png` (straight copy, 1983×793). Specs may only depend on committed files, and the `docs/reference-data` copy may be untracked, so the asset under `app/assets/images` is the one that counts.
- **Landing copy:** three About cards (title-case titles, 2–3 sentence bodies) drawn from the plan's description. Tell the user it's a first draft for them to edit.
- **Left nav:** only Views (the app's own `.left-nav-h3` + link with the app icon) and Documentation. Copy Documentation from the **current** Dossier branch in `_left_nav.html.erb`, not from an old commit: How To lists the app's own guide pages with `guide_pages_for_section(:<key>)` and only falls back to the plain User Guide link when there are none. Add an ACTIONS section or Reference Data links only once their pages exist. Dead links are worse than missing ones.
- **`UserAppSetting::LIVE_APPS` and the Start Page:** leave the app out until it has a setting of its own. When it is added later, `Authentication#preferred_start_page_url` needs a branch too. Say so in a comment, as Dossier did, and cover it with a spec ("leaves out <Brand> until it has a user setting of its own").
- **Policy:** add `when :<key> then "<key>"` to `app_name_for`. Model classes are added to that line in the blocks that create them.

### 5. Verify and refactor

```bash
ruby .claude/skills/new-app-scaffold/scripts/check_scaffold.rb --prefix Docket --key docket --brand Docket --route docket --icon list-checks
bundle exec rspec spec/features/pages spec/features/layouts spec/models/policy_spec.rb spec/models/app_permission_spec.rb spec/models/user_app_setting_spec.rb spec/models/guide_page_spec.rb spec/requests/left_nav_spec.rb
```

The script checks every touch point and the Apps menu order, and exits non-zero listing what's missing.

### 5b. Run CI's checks locally before pushing

`.githooks/pre-push` only validates commit messages. It does **not** run the scanners or the specs, so a push can pass locally and still fail on GitHub. Run what CI runs, with the same commands, before every push:

```bash
bin/brakeman --no-pager -i config/brakeman.ignore
bundle exec bundler-audit check --update
bin/importmap-audit
bin/rubocop
bundle exec rspec
```

**Brakeman exit code 5** ("Brakeman X is not the latest version Y") is not a security finding. `bin/brakeman` adds `--ensure-latest`, so CI fails as soon as a newer Brakeman is released, even on a branch that never touched the Gemfile. Fix it before pushing:

- `bundle update brakeman --conservative`, then rerun `bin/brakeman`;
- commit `Gemfile.lock` on its own as `Main: build: bump brakeman to <version>`;
- if the branch is already pushed and CI failed this way, add that commit to the same branch and push again.

`--ensure-latest` and `bundler-audit --update` need network access. If the sandbox blocks them, say so and give the user the commands to run, rather than reporting the checks as passed.

Finish with the manual check. Visit `/<route>` in `bin/dev` as a guest and as a content creator, open the Apps menu, and confirm the left nav. If localhost isn't reachable from this sandbox, ask the user to do it and say that you couldn't.

### 6. Record and hand off

- **CLAUDE.md:** add the app to "What this is" (`<Prefix>` → "<Brand>" (…): in progress, per the doc, Block 0 done). Add the enum key to the `app_name` list in the Roles section, and the prefix to the Apps list under Commit conventions.
- **Planning doc:** under Block 0, add a dated "**Done YYYY-MM-DD.** Decisions confirmed at the Block 0 gate:" list.
- **Commit:** `<Prefix>: feat: add the <Brand> app scaffold and landing page`, using the repo's single-space style. Push the branch only after step 5b is clean, then give the user a PR title and body to paste. `gh` can't create PRs with their token.
- Stop at the confirmation gate for Block 1.

## What not to do

- Don't create models, migrations or reference data in Block 0 unless the plan explicitly puts them there. Cookbook did, and its Block 0 commit grew to 39 files. Dossier didn't, and its scaffold stayed easy to review.
- Don't add `<%# path %>` comments to new `.html.erb` files. Do add `# path/to/file.rb` to new Ruby files.
- Don't edit stylesheets under `app/assets/stylesheets/base|layouts|components`. Only `application.css` is served, and the shared `app_landing` partial already has its styles.
- Don't create `docs/user-guide/<app>/` pages in Block 0. The User Guide comes with the features it describes.
