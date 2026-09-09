# TASK
* Plan the redesign/refactor of a the app landing pages to be shared across BergstromDomain. 
* **Confirmation gate:** before starting a new development block, summarise what you know so far (decisions made, assumptions carried forward) and ask me to confirm and/or answer any open design questions before progressing. Do not skip ahead to implementation on an unconfirmed block.
* Follow existing project conventions without restating them here: TDD (Red → Green → Refactor), the four-section spec structure (Happy / Negative / Alternative / Edge), the `<App>: <type>: <description>` commit format, and the bundler-audit → brakeman → rubocop → rspec pre-push chain. Flag it explicitly if this feature needs an exception to any of these.

---

# FEATURE DESCRIPTION
*(Fill in per feature — what should it do, from the user's point of view?)*
  * Each app should be added (alphabetically) to the 'Apps' dropdown menu
  * Each app should have a left navbar with the following sections (Use the existing Event Tracker as reference)
      * VIEWS
        * H2: [App name] 
          * [App name]				Link to app landing page
        * (Optional) H2: [Category/Type]	Example: People, Event, 
          * TBD
          * TBD
      * ACTIONS
        * (Optional) H2: [Category/Type] 
          * TBD
          * TBD
      * IMPORT & EXPORT
        * (Optional) H2: [Category/Type] 
          * TBD
          * TBD
      * HOW TO
        * (Optional) H2: [Category/Type] 
          * TBD
          * TBD
* Each app should have a landing page with the app name added to the routes file
* The landing page should have a title and a tagline (Example: Event Tracker landing page)
* The landing page should have an AI generated image using a prompt like below. Merge the prompt into the image template 
  Use a warm, colourful but restrained palette with 3–5 complementary colours. Use muted but clearly visible colours throughout the objects and illustrations. Avoid black-and-white, monochrome, grayscale or line-art-only imagery. Maintain an off-white or very light neutral background, with coloured objects, coloured details and subtle coloured shadows. The overall appearance should be sophisticated and cohesive rather than bright, childish or cartoon-like.

* The landing page should have a few paragraphs describing the apps key features



---

# SCOPE
* Event Tracker
  * Rename the app to 'Occasions'
  * Image has been created by ChatGPT using the prompt below. Keep it in this document for future use if/when layout and/or colorschema are changed
    * docs/context-prompts/active/Chronicle_image.png - Move it to the correct location, use it for the landing page and add it to git
    * Prompt: "Create a clean, modern editorial vector illustration representing Chronicle, a personal blog and knowledge collection.
The blog contains three major types of content: technical notes and development tips, travel stories and experiences, and climbing, hiking and outdoor skills.
Create a single cohesive composition centred around an open notebook or journal, representing the written collection. Around the notebook, include three distinct but visually connected groups of objects:
Technology: a laptop or computer screen, terminal/code symbols represented only as abstract lines and shapes, a Git-style branching diagram, and a small gear or development tool.
Travel: a small map, compass, backpack, airplane or mountain landscape, and a camera.
Climbing and hiking: a climbing carabiner, climbing rope, hiking boot, mountain peak and small outdoor equipment elements.
The three groups should feel like parts of the same personal collection rather than three separate illustrations. Use subtle connecting lines, overlapping objects or pages to bring them together.
Visual style: sophisticated minimalist editorial vector illustration, flat vector shapes, refined consistent line work, subtle layered depth, soft shadows, rounded forms and generous negative space. Use 3–5 complementary muted colours throughout the illustration with clearly visible coloured objects and details. Do not use black-and-white, grayscale or monochrome artwork. Keep the colours warm, natural and slightly desaturated rather than bright or cartoonish.
Use a very light neutral/off-white background. No gradients, no photorealism, no 3D rendering.
No text, no readable code, no letters, no numbers, no logos and no UI screenshots.
Landscape composition, approximately 16:9, designed to work as the hero illustration on a web application's landing page, with the main illustration positioned slightly to the left or centred and sufficient negative space around it."

* Chronicle
  * Image has been created by ChatGPT using the prompt below. Keep it in this document for future use if/when layout and/or colorschema are changed
    * docs/context-prompts/active/Occasions_image.png - Move it to the correct location, use it for the landing page and add it to git
    * Prompt: "Clean minimalist editorial vector illustration representing Occasions, a personal event tracker for people, birthdays, anniversaries, milestones and important events. The central object is a stylish open calendar or personal planner. Several calendar pages or date markers contain simple symbolic illustrations representing different occasions: a birthday cake, wedding rings, graduation cap, gift, celebration and travel. Include subtle connected lines or small relationship elements to suggest that events and people are connected.
The illustration should communicate remembering important dates, celebrating people and keeping track of life's milestones, rather than business scheduling or workplace meetings.
Use the same sophisticated visual language as a modern personal web application suite: flat vector artwork, refined consistent line art, simple geometric forms, subtle layered depth, very soft shadows, rounded corners, generous negative space and an understated editorial aesthetic. Warm neutral background with a limited palette and one muted accent colour.
No text, no letters, no numbers, no logos, no readable calendar dates. Avoid corporate calendars, office meetings or productivity imagery. Landscape composition, approximately 16:9, with the main illustration positioned slightly to the left or centred so it works beside introductory website content."


---

# DESIGN GUIDELINES
- Use existing design system tokens/components (colour tokens, `.show-panel` etc. conventions) rather than introducing new ones — flag if this feature genuinely needs a new token/pattern.
- Reuse existing JS conventions where applicable (e.g. Stimulus controllers like `dropdown_controller.js`) rather than a one-off script.
- Consistent with existing Authentication/Authorisation and Data Classification only if the feature is permission- or visibility-sensitive; otherwise N/A.

---

# BEHAVIOUR SPEC

---

# INTEGRATION / MIGRATION


---

# DECISIONS CONFIRMED (2026-09-09)
* **Rename scope is brand-only.** "Event Tracker" becomes "Occasions" in user-facing
  text only (dropdown label, left-nav VIEWS heading/link, landing page title/tagline,
  home page copy, hero image). Technical identifiers are untouched: `AppPermission`
  enum stays `event_tracker`, routes stay `event_tracker_path`/`PagesController#event_tracker`,
  CSS/testid identifiers keep their `event-tracker`/`event_tracker` naming, and the
  commit prefix stays `Event_Tracker:`. Mirrors the existing Chronicle precedent
  (brand name "Chronicle" vs. technical `BlogPost` model / `Blog_Posts:` commit prefix).
* **The two hero images were swapped in this doc's SCOPE section** — corrected:
  `Occasions_image.png` (calendar/cake/rings) → Occasions (renamed Event Tracker)
  landing page; `Chronicle_image.png` (notebook/laptop/travel/climbing) → Chronicle
  landing page.
* **No changes to `.githooks/commit-msg`/`.gitmessage`** as part of this feature. The
  Retrofit block's "update git validation" line is addressed by adding a step to
  `App_-_TEMPLATE.md` reminding future *new* apps (Docket, Cookbook, Gallery) to
  register their name in the commit-msg hook's `APPS` list — not by renaming the
  existing Event_Tracker/Blog_Posts entries.
* **Chronicle's Import & Export left-nav section stays deferred**, per the earlier
  deliberate decision to hold off until there's real post content — out of scope here.

---

# DEVELOPMENT BLOCKS
*(Replaces the original generic Core Component / Trigger API / Behaviour-Interaction
skeleton, which didn't match this feature's actual scope — see Decisions above.)*

## Block 1 — Occasions rename (brand-only) + shared landing-page layout redesign — DONE
* Renamed "Event Tracker" → "Occasions" in: Apps dropdown label, left-nav VIEWS
  H3/link (`app/views/layouts/_left_nav.html.erb`), landing page title/tagline
  (`app/views/pages/event_tracker.html.erb`), home page hero copy
  (`app/views/pages/home.html.erb`).
* **Scope grew mid-block**: replaced the shared `app_landing` partial's old
  side-by-side layout with a new full-width-hero + 3-overlapping-cards layout
  (see reference screenshot `tmp/screenshots/landingpage_layout_idea.jpg`), per a
  design pivot mid-implementation. `about` locals are now `{title:, body:}` hashes,
  not plain strings — both `event_tracker.html.erb` and `chronicle.html.erb` updated.
  New CSS: `.app-landing__hero`/`.app-landing__hero-image`/`.app-landing__cards`/
  `.about-card__title` in `application.css`.
* Two real pre-existing bugs found and fixed along the way (not part of this
  feature's ask, but blocking it): (1) the About page (`pages/about.html.erb`)
  independently reused the `.split-layout` classes this block almost deleted —
  restored them alongside the new classes; (2) a dead, unreferenced
  `.app-landing__hero`/`__about-*` CSS block from an earlier design iteration
  collided by name with the new classes — removed.
* `occasions-hero.png` (moved from `docs/context-prompts/active/Occasions_image.png`)
  wired in; old `event-tracker-hero.png` removed.
* Chronicle's card titles ("Write & Format" / "Draft to Publish" / "Public and
  Private Posts") were proposed and confirmed with the user (2026-09-09), since the
  original doc only specified Occasions' copy.
* **Known follow-up, not a defect**: `occasions-hero.png` (1672×941, 16:9) gets
  moderately cropped by `object-fit: cover` at typical desktop widths, since the
  hero container's real aspect ratio (~2.5:1) is wider than 16:9. See DEFERRED below.

## Block 2 — Hero image regeneration + swap-in (Occasions + Chronicle) — DEFERRED, pending user
* User is regenerating both hero images tomorrow at a wider aspect ratio (~2.5:1–3:1
  "ultra-wide banner" instead of 16:9) to reduce/eliminate the cover-crop described
  above. Once ready: swap `occasions-hero.png` for the new version, and move
  `Chronicle_image.png` → `app/assets/images/chronicle-hero.png` (replacing the
  current placeholder-text hero, which was never swapped in this session).
* Decide then whether to also update `Image_Prompt_-_TEMPLATE.md`'s aspect-ratio
  guidance for future apps' heroes (Docket/Cookbook/Gallery) to match.

## Block 3 — Apps dropdown alphabetical order — DONE
* Reordered `app/views/layouts/_top_nav.html.erb`'s Apps dropdown items to
  Chronicle, Occasions (alphabetical). Added an order-asserting spec to
  `top_nav_spec.rb`.

## Block 4 — Retrofit — PARTIALLY DONE
* Added a step to `docs/context-prompts/templates/App_-_TEMPLATE.md`'s Definition
  of Done documenting: for a brand-new app's first block, confirm its name exists
  in `AppPermission`'s `app_name` enum and `.githooks/commit-msg`'s `APPS` list,
  adding whichever is missing. DONE.
* Full `rspec`/`rubocop`/`brakeman`/`bundler-audit` pass: DONE for Blocks 1 and 3.
  Re-run once more after Block 2 lands.
* Manual browser check: still outstanding — ask the user to eyeball `bin/dev`
  once Block 2's images are in.
---

# DEFINITION OF DONE (per block)
* Spec covers Happy / Negative / Alternative / Edge cases
* Red → Green → Refactor followed; full suite green, coverage not regressed
* RuboCop and Brakeman clean; bundler-audit clean
* Commit(s) follow `<App>: <type>: <description>` format
* All retrofitted call sites verified, old pattern fully removed (no dual implementations left behind)
* Confirmed with me before moving to the next block

---

# DEFERRED / PHASE 2
*(Log things explicitly instead of burying "add later" notes in prose.)*
*

# OPEN QUESTIONS
*(Running log of unresolved design questions raised during planning.)*
*
