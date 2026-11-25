# Block 0 checklist

These are the touch points of a new app's scaffold. They were taken from the Dossier scaffold (commit `30118dd`, 17 files) and the commit-tooling commit before it (`e809331`). `git show 30118dd` gives the full diff, but shared code has moved on since then (the left nav's Documentation section, for one). **Copy from the current Dossier code in the working tree, and use the old commit only as a list of which files to touch.**

The examples use **Docket**: prefix `Docket`, key `docket`, route `docket`, brand `Docket`. Substitute your names.

`scripts/check_scaffold.rb` checks items 1–20 automatically, apart from the content of the specs. Items marked *(by hand)* it can't judge.

## Commit tooling: first commit, `Main: build: …`

1. `.githooks/commit-msg`: add `Docket` to `APPS="Main|Event_Tracker|Blog_Posts|Recipes|Dossier|Docket|Photo_Album"` and to the help `echo` line below it.
2. `.githooks/pre-push`: the same `APPS=` regex.
3. `.github/workflows/commit-lint.yml`: the same `APPS=` regex.
4. `.gitmessage`: add a `# Docket` line in the apps comment list.

## Enums and authorisation

5. `app/models/app_permission.rb`: add `docket: "docket",` to `enum :app_name`, before `photo_albums`.
6. `app/models/user_app_setting.rb`:
   - add `docket: "docket",` to `enum :app_name`;
   - add `"docket" => "Docket"` to `DISPLAY_NAMES`;
   - **don't** add it to `LIVE_APPS` yet. Add a comment instead: `# Docket is left out until it has a per-user setting of its own.`
7. `app/models/guide_page.rb`: add `docket: "docket",` to `enum :app_section` (before `admin`), and `"docket" => "Docket"` to `APP_SECTION_LABELS`.
8. `app/models/policy.rb`: in `app_name_for`, add `when :docket then "docket"` above the `:photo_albums` line.

## Routing, controller, navigation

9. `config/routes.rb`: add `get "docket", to: "pages#docket", as: :docket` next to the other landing pages (`event_tracker`, `chronicle`, `cookbook`, `dossier`).
10. `app/controllers/pages_controller.rb`:
    - add `docket` to `skip_before_action :set_left_nav, except: %i[ … ]`;
    - add `docket` to `allow_unauthenticated_access only: %i[ … ]` (landing pages are public, unless the user answered otherwise);
    - add an empty `def docket; end` action.
11. `app/controllers/concerns/navigable.rb`: add `return :docket if controller == "pages" && action == "docket"`.
    - If the app's controllers will live under a namespace (`Docket::`), also add `return :docket if controller_path.start_with?("docket/")`.
    - Otherwise add its controller names to the `case` in the block that creates them.
12. `app/views/layouts/_top_nav.html.erb`: add `{ label: "Docket", path: docket_path }` to the Apps `items:` list **in alphabetical order of label**.
13. `app/views/layouts/_left_nav.html.erb`: add an `<% elsif @left_nav_section == :docket %>` branch. Copy the current `:dossier` branch's shape, minus its Actions and Reference Data:
    - a Views section with a `left-nav-docket-h3` heading and a link to `docket_path` with the app icon;
    - a divider;
    - Documentation › How To, listing `guide_pages_for_section(:docket)` as `left-nav-guide-page-link`s, falling back to the plain `user_guide_path` "User Guide" link when the app has no guide pages yet (which it won't in Block 0).

    Use the same collapsible-section markup (`left_nav_section_collapsed?`, `left_nav_section_toggle`). `scripts/check_scaffold.rb` checks for `guide_pages_for_section(:docket)`.

## Landing page

14. `app/views/pages/docket.html.erb`: a page header (`page-header--centered`, `h1.page-title`, `.page-header__subtitle`), then `render "shared/app_landing"` with `app_name:`, `hero_image: "docket-hero.png"` and three `about:` cards. No `<%# path %>` comment on line 1.
15. `app/assets/images/docket-hero.png`: copy of `docs/reference-data/docket/Docket_Landingpage_Wide.png`. *(Checked for existence. If the source image is missing, tell the user. Don't substitute another app's hero.)*

## Specs (written first: Red)

16. `spec/features/pages/docket_spec.rb`: new file, four sections, modelled on `spec/features/pages/dossier_spec.rb`:
    - **Happy:** heading and subtitle; the hero image renders through `[data-testid='app-landing']` with `alt='Docket preview'`; three About card titles; the left nav has the `left-nav-docket-h3` heading, a link back to `docket_path`, and a User Guide link.
    - **Negative:** the left nav shows no other app's links; Uno User sees no `left-nav-actions-h2`.
    - **Alternative:** reachable from the Apps menu (`click_button "Apps"`, `click_link "Docket"`); reachable by Charlie.
    - **Edge:** Gary Guest sees it without signing in (a Sign In link is present).
17. `spec/features/layouts/top_nav_spec.rb`:
    - add a "Shows 'Docket' link in the 'Apps' dropdown menu" example;
    - update "Lists the apps alphabetically: …" so both the title and the `%w[…]` list include the new app in order.
18. `spec/models/policy_spec.rb`: a `context "Docket (…)"` under `can_create?`:
    - guest false; app_user false; content_creator, admin and system_admin true;
    - a `docket` AppPermission override grants an app_user and revokes a content_creator;
    - another app's override doesn't apply.
19. `spec/models/app_permission_spec.rb`, `spec/models/user_app_setting_spec.rb`, `spec/models/guide_page_spec.rb`:
    - add `docket` to the valid-name lists;
    - display-name/label examples;
    - "leaves out Docket until it has a user setting of its own".
20. `spec/requests/left_nav_spec.rb`: "treats the Docket landing page as its own section" (`get docket_path`, then `current_session.reload.left_nav_section == "docket"`).

## Docs

21. `CLAUDE.md`: the "What this is" bullet, the `app_name` enum list in Roles vs. classification, and the Apps list under Commit conventions. *(by hand)*
22. The planning doc: a "Done YYYY-MM-DD. Decisions confirmed at the Block 0 gate:" list under Block 0. *(by hand)*

## Deliberately not in Block 0

- `UserAppSetting::LIVE_APPS`, and the matching `Authentication#preferred_start_page_url` branch: add them when the app gets its own Settings page.
- Models, migrations, factories and reference data: Block 1+ (unless the plan says otherwise).
- ACTIONS / Reference Data left nav groups: add them with the pages they link to.
- `docs/user-guide/<app>/` pages and the story chapter: add them with the features they describe.
