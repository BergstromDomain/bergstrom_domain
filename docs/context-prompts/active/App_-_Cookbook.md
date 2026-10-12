#TASK
* Plan the development of 'Cookbook', a recepies app to be integrated into BergstromDomain
* Outline the main development blocks for developing the app. Before starting a new development block, summarise what you know and ask me to confirm and/or answer any design questions before progressing
* Follow previously TDD methodology with clear tests, keeping the test coverage above 95% and follow previously established guidelines
* Create a new feature branch and add this file

#APP OVERVIEW
- The app should allow Content Creators to
  * Create and Publish recepies
  * List his/hers Published and Draft recepies - Same behaviour as for Chronicle
  * Edit his/hers recepies 
  * Delete his/hers recepies
- Recepies should contain metadata such as Owner, Cuisine, # Of Serveings, Food Type, Cooktime, Language, Stars, Comments
- The app should allow Users to 
  * Browse recipies by Cuisine or Food Type - Same behaviour as for Chronicle
  * Filter recipies by metadata - Same behaviour as for Chronicle
- Use the existing Authentication, Authorisation and Classification 
- The app should have it's own landing page, left nav bar and footer
- The app should have the same Toasts, Likes and Comment functionality as Chronicle
- The app should have similar Import and Export functionality as the other apps
- The app shuld have it's own header in the User Guide
- All pages to be full with of the main frame
- All Referece data pages should be half size - Same a Create Blog Post Category


#DETAILED DESIGN
## Apps menu and landing page
* Cookbook to be added (alphabetically) to the apps menu
* Landing page similar to Chronicle
* Image has been created by ChatGPT using the prompt below. Keep it in this document for future use if/when layout and/or colorschema are changed
    * docs/context-prompts/active/Cookbook_Landingpage_Wide.png - Move it to the correct locationand and add it to git 

Clean minimalist editorial vector illustration representing Cookbook, a personal collection and database of recipes. The central object is an open recipe book or cookbook on a simple kitchen surface. Surround it with a small selection of recognisable cooking elements such as a wooden spoon, whisk, bowl, herbs, vegetables and a few ingredients. The objects should feel carefully arranged rather than cluttered.

The illustration should communicate home cooking, recipes, collecting favourite dishes and discovering what to cook, rather than a restaurant or professional chef environment.

Use the same sophisticated visual language as a modern personal web application suite: flat vector artwork, refined consistent line art, simple geometric forms, subtle layered depth, very soft shadows, rounded corners, generous negative space and an understated editorial aesthetic. Warm neutral background with a limited palette and one muted accent colour.

No text, no letters, no numbers, no logos and no readable recipes. Avoid excessive food detail. Landscape composition, approximately (~2.5:1–3:1), with the main illustration positioned slightly to the left or centred so it works beside introductory website content.


## Left nav bar
* Similar to Chronicle
  H1 VIEWS
    H2 COOKBOOK
      * Cookbook			Link to landing page
    H2 RECIPIES
      * Browse Recipies By Cuisine	Same behaviour as for Chronicle 
      * Browse Recipies By Food Type	Same behaviour as for Chronicle
      * Filter Recipies			Same behaviour as for Chronicle
    H2 MY RECIPIES
      * My Published Recipies		Same behaviour as for Chronicle
      * My Draft Recipies		Same behaviour as for Chronicle
					Add a TODO to the file 'Feature_-_Style.md' to update Chronicle left nav to use 'Draft' instead of 'Unpublished'
    H2 REFERENCE DATA			Add a TODO to the file 'Feature_-_Style.md' to update Occasions and Chronicle left nav to use 'REFERENCE DATA' instead of 'CATEGORIES'
      * Cuisines			Same behaviour as for Chronicle
      * Food Types			Same behaviour as for Chronicle
  H1 ACTIONS
    H2 NEW 				Add a TODO to the file 'Feature_-_Style.md' to update Occasions and Chronicle left nav to add this H2
      * Write A Recipie			Same behaviour as for Chronicle
      * Add A Cuisine			Same behaviour as for Chronicle
      * Add A Food Type			Same behaviour as for Chronicle
    H2 IMPORT & EXPORT 			Add a TODO to the file 'Feature_-_Style.md' to update Occasions and Chronicle left nav to move the Import sections as a subsection under Actions
      * Download Recipies		Same behaviour as for Chronicle
      * Import Recipies			Same behaviour as for Chronicle
  H1 DOCUMENTATION
    H2 HOW TO
      * User Guide			Same behaviour as for Chronicle

* Design Question-1: Suggest a few options of what to do when the number of items in the left nav bar does not fit on the page and list pros and cons for these options
  * I have identified 2 options, add another one if possible
  1) Have each H1 collapsable/expandable 
  2) Have a left nav scroll bar
* Design Question-2: Show/Hide left nav bar to increase the 'main frame'
  * Should this be developed as a separate feature and then use that on all nav bars, i.e. dont do it as part of this work?


## Write A Recepie
* Title Frame
  * Title 		String			Mandatory
  * Description		Text			Optional
  * Recepie Image	Upload image		Optional
  
* Metadata Frame
  * Food Type		Dropdown list		Mandatory for Publishing but not for Create
						Food Type is Reference data and CRUD functionality should be created for Admins
  * Cuisine		Dropdown list		Mandatory for Publishing but not for Create
						Cuisine is Reference data and CRUD functionality should be created for Admins
						Design Question-3, see below
  * Serves/Makes	Number			Optional
						Normally Serves 2 but when baking the text should say 'Makes: 24'
						Two fields avalable to populate with an 'or' between them
						The logic for Show should be 'if Makes is pupulated use that, else use Serves (even if both are blank)
  * Cooktime		String			Optional
  * Language		Dropdown list		Mandatory for Publishing but not for Create
						Design Question-3, see below

  
* Ingredience Frame
  * H1: Ingredience
    * H2: Header	Optional		Lasagna is a good example where there will be 3 ingredience lists, 1) The meat sauce 2) The white sauce, 3) Assembling
      * Table with ingrediences			* Add Ingredience button - This should add a blank row
      	 * Remove Ingredience Icon		* Ability to delete a row
      * Table columns
	* Quantity	Mandatory		Number
        * Measurement	Optional		String
        * Ingredient	Mandatory		String	Examples: '2 dl sugar, 3 (blank) eggs
        * Comments	Optional		Text
    * H2: Header 				Ability to add multiple H2 headers with list of ingrediences

* Description Frame
  * Similar to Chronicle - A large text box with 'Raw/Formatted' allowing the author to descrie the recipie and add images on some of the steps

* Action Frame
  Cancel | Save


## Read a recipie
* Title Frame
  * Title | Language icon (right aligned)
  * Description		Dont include if blank
  * Recepie Image	If no image, display the Cuisine icon

 
* Metadata Frame
  * Food Type icon | Cuisine icon
  * Serves/Makes: + value | Cooktime: + value
  * Chef: + owner of the recipie
  * Comments Count - Same behavior as Chronicle
  * Likes count - Same behavior as Chronicle

* Ingredience Frame
  * H1: Ingredience
    * H2: Header	Optional
      * Table with ingrediences	
  
* Description Frame


* Comments 
  * List of comments - Same behavior as Chronicle
  
* Action Frame
  Back (Design Desision-4) | Edit | Publish/Unpublish | Delete		Edit, Publish/Unpublish and Delete only available on your own recipies. Publish/Unpublish depending on current status

## Edit a recipie
* ~~After each edit, the recipie should be Draft~~ Superseded at the Block 5 gate: a published
  recipe stays published after an edit; the owner can Unpublish it manually.

## Delete a recipie
* The Owner's should be able to delete a recipie
* Deleted recipie to be stored for 30 days (restorable by admins). Same functionality as for Chronicle

## CRUD Food Type
* Similar behaviour as for Event Type
* Available for Admin and Sys Admin

## CRUD Language
* Similar behaviour as for Event Type
* Available for Admin and Sys Admin

## CRUD Cuisine
* Similar behaviour as for Event Type
* Available for Admin and Sys Admin


## User Settings
* The App should have it's own user settings page, same as for Chronicle



## Design Question-3
* I want to have icons for Language and for Cuisine
* The challenge becomes how to distinguish between a Swedish dish written in English and an English dish written in Swedish?
* To start with I will only have Swedish and English languages. I can see Spanish, French and German being added in the future but I doubt that the website will grow beyond that
* I would probably have 20 cuisines to start with but that list might grow
* List a few options on how to support this
  * Option 1 - Merge Flag with 'utensils' icon for Cuisine and 'book-open-check' for Language. Can this be done by the app or should Admin upload generated icons when adding these?
    Example: Swedish_Cuisine.png

## Design Question-4
* From the Show page when clicking on the Back button. How can I store breadcrumbs to know from where the user navigated to the Show page (Browsed, Filtered, My Recipies, etc?


## DECISIONS LOG (updated during planning, 2026-09-17)
* **Naming**: code-side uses `Recipe`/`Recipes` throughout (not "Recepie") — matches the
  `recipes` enum already reserved in `AppPermission` and the `Recipes` commit-prefix already
  reserved in `.githooks/commit-msg`/CLAUDE.md. No scaffolding changes needed for either.
* **Landing hero image**: moved from `docs/context-prompts/active/Cookbook_Landingpage_Wide.png`
  to `app/assets/images/cookbook-hero.png` and added to git (the ChatGPT prompt stays above, in
  this doc, per the original instruction).
* **Left-nav wording TODOs** (Draft vs. Unpublished, REFERENCE DATA vs. CATEGORIES, NEW H2,
  Import & Export placement, DOCUMENTATION H1/HOW TO H2) logged in
  `docs/context-prompts/active/Feature_-_Style.md` — not part of Cookbook's own build, since they
  retrofit Occasions/Chronicle.
* **Design Question-1/2 (left-nav overflow, show/hide sidebar)**: out of scope for Cookbook — the
  left nav already has `overflow-y: auto` and scrolls without any new code. Both ideas spun out
  into their own doc, `docs/context-prompts/active/Feature_-_Collapsible_Navbar.md`, to be picked
  up later.
* **Design Question-3 (Cuisine/Language icons)**: flag emoji (e.g. 🇸🇪) stored on each
  Cuisine/Language row, rendered with a small Lucide icon badge overlay via CSS — `utensils` for
  Cuisine, `book-open-check` for Language. No admin-uploaded composite images (the
  `Swedish_Cuisine.png` ChatGPT example stays as a reference only, not the shipped approach); no
  new asset-generation step per entry.
* **Design Question-4 (Back-button breadcrumb)**: `return_to` query param. Browse/Filter/My
  Recipes links append `?return_to=<path>` when linking into a recipe's Read page; the Back
  button uses that param (validated as a relative path only, to avoid open-redirect). Also logged
  as a retrofit TODO for Chronicle/Occasions in `Feature_-_Style.md`, so all three apps end up
  consistent.
* **Reactions (formerly Likes)**: originally a static placeholder, because `Like` was hard-wired
  to `BlogPost`. **Superseded 2026-10-11:** `Like` is now polymorphic (`Likeable`, PR #73) and is
  called "Reactions" in the UI. Cookbook ships **real Reactions** in the Read block.
  * Still needed: `LikesController#set_likeable` is hard-coded to `BlogPost`, so generalise it.
    The reaction row and breakdown popup are inline in `blog_posts/show.html.erb`; extract them
    into a shared partial that Chronicle uses too.
  * The overview's "Stars" metadata is dropped in favour of Reactions.
* **Comments**: generalized to polymorphic (`belongs_to :commentable, polymorphic: true`,
  replacing `Comment`'s former `belongs_to :blog_post`) — shared by Chronicle and Cookbook now,
  and by future apps going forward, rather than duplicating a `RecipeComment` model. Planning
  spun out into `docs/context-prompts/active/Update_Feature_-_Comments.md` (2026-09-19), not
  paired with the Likes rewrite above, addressed as its own feature — **shipped independently,
  2026-09-20**, ahead of Cookbook's own timeline; doc moved to
  `docs/context-prompts/archive/Update_Feature_-_Comments.md`. See Development Blocks below for
  what's still needed on Cookbook's side (the `comments_count` column, `include Commentable` on
  `Recipe`).
* **Ownership**: Recipe is single-owner only — no co-author shuttle like Chronicle's `BlogPost`
  (the app overview only ever says "his/hers recipe").

## PREREQUISITE REVIEW (2026-10-11, before resuming)
Checked against `main` after PRs #73–#83. Done: Comments generalised (#76), Likes → Reactions
(#73), Collapsible Navbar (#74), User Guide (#78), Reference Data PROD checklist (#79),
Import/Export redesign (#80), shared Browse drill-down `BrowseTree` (#81), N+1 guard (#83), and 5
of the 6 left-nav structure TODOs (`docs/context-prompts/archive/Update_Feature_-_Layout_and_Style.md`).
Cookbook-side gaps found, all folded into the blocks below:
* `CommentsController#set_commentable` and `comments/_form.html.erb` still assume `BlogPost`.
* `LikesController#set_likeable` is `BlogPost`-only; the reaction UI is not a shared partial.
* `GuidePage#app_section` has no `recipes` value. `UserAppSetting::LIVE_APPS` and the top-nav
  Apps menu don't list Cookbook.
* CLAUDE.md's "What this is" section still says only Event_Tracker is implemented.
* `return_to` breadcrumb (Design Question-4) is still unbuilt; the Style doc deferred it until
  Cookbook.

## DECISIONS (2026-10-11)
* **Reactions**: real, not a placeholder. See the Reactions entry above.
* **Cuisine, Food Type and Language are required on every save**, drafts included. Same as
  Chronicle's Category since PR #81, which removed "Uncategorized" from Browse, Filter and Import.
  Supersedes "Mandatory for Publishing but not for Create" in Write A Recipe above.
  * **Language defaults from the user's Cookbook settings** when left empty, so a recipe can
    always be saved. This needs a per-user default Language, so Cookbook Settings moves forward
    to Block 2, ahead of Create.
* **Import/Export**: **Download Recipes** is in scope: a Filter-style page, CSV plus a ZIP of
  PDFs, reusing `PdfRenderingService`/`ZipBundlingService`, the same as Chronicle.
  **Import Recipes is deferred**: a recipe's several ingredient sections don't fit one CSV row.
  Revisit later, likely as a Dev→Prod ZIP-with-manifest like Chronicle's. Left nav shows
  "Download Recipes" only until then.
* **`return_to` breadcrumb**: built as a shared, app-agnostic concern while building Cookbook.
  Chronicle and Occasions adopt it afterwards in a separate small follow-up PR.
* **Browse**: "Browse Recipes By Cuisine" and "Browse Recipes By Food Type" are each a one-level
  `BrowseTree` (`app/services/browse_tree.rb`): the tree, then a breadcrumb and newest-first
  preview panel at the leaf. No new browse engine.
* **This doc** stays in `docs/context-prompts/active/` and lives on branch `feature/cookbook`.

## DEVELOPMENT BLOCKS (revised 2026-10-11)
0. **Foundation**: models and migrations for `Recipe`, `Cuisine`, `FoodType` and `Language`.
   * `Recipe` gets a `comments_count` column (`null: false, default: 0`) for `Comment`'s
     polymorphic counter cache, plus soft-delete (`deleted_at`) and Classification.
   * Routes, landing page with the hero image, and Cookbook in the top-nav Apps menu
     (alphabetical).
   * Left-nav skeleton.
   * `recipes` added to `GuidePage#app_section` (label "Cookbook") and
     `UserAppSetting::LIVE_APPS`.
   * Update CLAUDE.md's "What this is" section.
   * **Done 2026-10-11.** Decisions confirmed at the Block 0 gate:
     * **Cuisine**: name, description and flag. **Language**: name, a 2-letter code (`sv`,
       `en`; stored lower case, unique) and flag. **Food Type**: name, description and a
       Lucide icon, like Blog Categories.
     * A flag is any single emoji (`Flaggable` concern), so a regional Cuisine can use 🌍.
     * Language fallback: the form pre-selects the user's default; if both are empty, save
       fails with "Language can't be blank" (built in Blocks 2 and 3).
     * Serves/Makes are optional positive whole numbers; `Recipe#portions` returns Makes if
       set, otherwise Serves. Cooktime is free text.
     * Left-nav links are added only once their page exists (no dead links).
     * Landing-page copy is a first draft for the user to edit.
     * The Cookbook start-page choice in Preferences goes to the landing page until
       Cookbook Settings (Block 2) adds sub-page choices.
1. **Reference Data CRUD** (Cuisine, Food Type, Language): mirrors `EventTypesController` and
   `BlogCategoriesController`.
   * Half-width pages; flag emoji plus a Lucide icon badge (Design Question-3); admin-only.
   * Add `docs/reference-data/cookbook/` to the PROD reference-data checklist.
   * **Done 2026-10-11.** Decisions confirmed at the Block 1 gate:
     * Languages get their own left-nav link and an "Add A Language" action, alongside
       Cuisines and Food Types.
     * Starting lists come from the user: 18 Cuisines, 14 Food Types, 5 Languages. Seeded by
       `db/seeds/cookbook.rb` and listed in `docs/reference-data/cookbook/`. Spelling fixed
       in two names: "Pilipino" → "Filipino", "Deserts" → "Desserts".
     * Food Type icons are a first draft for the user to review. Lucide has no pasta or pie
       icon, so Pasta uses `cooking-pot` and Pies uses `croissant`.
     * Flag badge (`shared/_flag_badge.html.erb`) styled in CSS, reviewed in the browser
       rather than mocked up first.
     * Left-nav Actions shows only for admins until Block 3 adds Write A Recipe.
     * Delete is refused while recipes use the row ("Cannot delete record because dependent
       recipes exist").
2. **Cookbook Settings**: mirrors the Chronicle/Occasions Settings pages (start page, default
   Classification) plus a **default Language**, which Create needs. Moved forward from the old
   Block 9.
   * **Done 2026-10-11.** Decisions confirmed at the Block 2 gate:
     * Start Page choices are added as each page is built. Today the choices are Cookbook,
       Cuisines, Food Types and Languages.
     * Default Language is the saved choice, otherwise English (`code: "en"`), via
       `UserAppSetting#effective_default_language`. If neither exists, the page asks
       "Select a Language".
     * Deleting a Language clears anyone's default for it (FK `on_delete: :nullify`). A
       Language that recipes use still can't be deleted.
3. **Create a Recipe**:
   * Title/Description/Image frame.
   * Metadata frame: Cuisine, Food Type and Language required; Language pre-filled from settings.
   * Ingredients frame: a new two-level dynamic add/remove (sections, then rows).
   * Description/body frame: Raw/Formatted, reusing Quill and `convert_format`.
   * Action frame: Cancel | Save.
   * **Done 2026-10-11.** Decisions confirmed at the Block 3 gate:
     * Quantity is mandatory free text ("½", "2–3", "a pinch"). Ingredient is mandatory;
       Measurement and Comment are optional. A completely blank row is ignored.
     * Every list heading is optional. The form starts with one unheaded list holding one
       blank row; an untouched starting list is not saved.
     * Stored in `ingredient_sections` and `ingredients` tables, each with a `position`
       set from the submitted order (`Recipe#assign_ingredient_positions`).
     * Serves and Makes are both kept when both are filled in; Makes is displayed.
     * Save returns to the Cookbook landing page until the Read page exists (Block 4).
     * Shared pieces extracted along the way:
       * `blog_post_editor_controller.js` became `markdown_editor_controller.js`.
       * The body frame became `shared/_markdown_editor.html.erb`.
       * `#convert_format` became the `FormatConvertible` concern, so the Recipe editor
         doesn't depend on Chronicle create permission.
     * The left-nav Actions section now shows for content creators, with Write A Recipe.
4. **Read a Recipe**: Title, Metadata, Ingredients, Description, Reactions, Comments and Action
   frames.
   * Back button uses the new shared `return_to` concern.
   * **Real Reactions**: generalise `LikesController` and extract the shared reaction partial
     (Chronicle switches to it too).
   * **Done 2026-10-11.** Decisions confirmed at the Block 4 gate:
     * Ingredients read like a printed recipe: one list per section under its heading
       (if any), each row showing "5 dl" then "yellow peas", with the comment in grey italics.
     * Blank Description, Serves/Makes and Cook Time are hidden, not shown as empty labels.
     * Chef shows the owner's full name with their profile thumbnail.
     * A recipe with no image shows its Cuisine flag badge; the Language flag sits right of
       the title.
     * `ReturnTo` concern (`return_to_or(fallback)`): only a relative path on this site is
       honoured, so `//host` and absolute URLs fall back. Back falls back to the Cookbook
       landing page until Browse exists.
     * Reactions: `LikesController` serves both `blog_posts/:id/like` and `recipes/:id/like`.
       The shared partials are `shared/_reactions_score`, `shared/_reactions_panel` and
       `shared/_reactions_breakdown` (was `blog_posts/_likes_breakdown`).
     * Save now opens the new recipe's Read page.
5. **Edit + Publish/Unpublish a Recipe**: a combined block, like Chronicle's.
   * **Done 2026-10-12.** Decisions confirmed at the Block 5 gate:
     * Unlike Chronicle, an edit leaves a published recipe published. Unpublish is a manual
       action on the Read page.
     * Publishing needs a Method (the body, now labelled "Method" in error messages) and at
       least one ingredient. Checked on every save while published, so an edit can't remove
       the last ingredient of a published recipe either.
     * Edit, Publish and Unpublish follow `Policy#can_update?`: the owner, admins, and the
       Cookbook `AppPermission` override. Action frame: Back | Edit | Publish/Unpublish.
     * Edit reuses `recipes/_form`; Cancel returns to the Read page. A failed Update keeps
       rows and lists already removed hidden, with `_destroy` still set.
     * Also fixed: the metadata grid's Cuisine cell sat higher than the others (the stacked
       `.show-panel__section` top margin applied to every cell but the first).
6. **Delete a Recipe**: soft-delete, 30-day retention, admin restore; mirrors
   `PurgeDeletedBlogPostsJob`.
   * **Done 2026-10-12.** Decisions confirmed at the Block 6 gate:
     * A published recipe can be deleted directly, without unpublishing first.
     * Restore brings a recipe back exactly as it was, published or draft.
     * Delete follows `Policy#can_delete?`; Deleted Recipes and Restore are admin-only.
       The left nav link sits after "Add A Language", as Chronicle's "Deleted Posts" does.
     * `PurgeDeletedRecipesJob` runs daily at 3am (production `config/recurring.yml`) and
       destroys ingredient lists, ingredients, reactions and the image with the recipe.
     * Delete and Restore write `deleted_at` without validations, so a recipe that no
       longer meets the publishing rules can still be deleted and restored.
7. **Comments**: wire up Recipe. Generalise `CommentsController#set_commentable` and
   `comments/_form.html.erb`'s BlogPost-only URL.
   * **Done 2026-10-12.** Decisions confirmed at the Block 7 gate:
     * Same rules as Chronicle: anyone signed in who can read the recipe can comment and
       reply; guests see the threads but no comment box.
     * Comments are allowed on drafts (so the owner and admins can keep cooking notes).
     * `CommentsController::COMMENTABLES` picks the parent from the matched route (mirrors
       `LikesController::LIKEABLES`); the form posts to `polymorphic_path([commentable, :comments])`.
     * Recipes nest only `comments#create`; update/destroy reuse the shallow `comments/:id`.
     * The comments panel is now `shared/_comments_panel.html.erb`, used by both show pages.
8. **Multiple Cuisines and Food Types**: a recipe has one or two of each (e.g. Swedish
   lasagna: Swedish + Italian, Pasta + Mince Meat). Inserted 2026-10-12, before Browse, so
   Browse and Filter are built on it rather than rewritten.
   * Decisions confirmed 2026-10-12:
     * Join tables (`recipe_cuisines`, `recipe_food_types`) with a `position`; the first value
       is the primary one (Read-page image fallback, Filter sort). At least one, at most two.
       Rejected: a `secondary_cuisine_id` column (every query ORs two columns; a third value
       means another migration).
     * Language stays single.
     * Form: a required first dropdown plus an optional second one.
     * `BrowseTree` association levels learn many-to-many, so a recipe counts under both.
     * `Jql::Evaluator` accepts list values: `=` matches any, `!=` matches none, `CONTAINS`
       checks each.
     * Deleting a Cuisine or Food Type is still refused while recipes use it.
   * **Done 2026-10-12.** Notes from the build:
     * `Recipe#cuisines=`/`#cuisine_ids=` (and the Food Type pair) only build or mark join
       rows, so nothing saves until the recipe does; a failed update leaves the saved choices
       alone. Blanks, duplicates and unknown ids are dropped, so a "Second Cuisine" chosen on
       its own becomes the primary one.
     * Errors sit on `:cuisines`/`:food_types` but read "Cuisine can't be blank" and
       "Food Type can't be blank" (`config/locales/en.yml`); the old "Food type" spelling is
       gone.
     * The Read page labels the cell "Cuisines"/"Food Types" when there are two, separated
       by "·"; the image fallback uses the primary Cuisine's flag.
     * The migration copies each existing recipe's Cuisine/Food Type into the join tables;
       rolling back keeps only the primary one.
9. **Browse + Filter**:
   * Browse by Cuisine and by Food Type: two one-level `BrowseTree`s.
   * Filter: Basic/SQL via a new `RecipeFilter` on `Jql::Parser`/`Jql::Evaluator`.
   * Add the list pages to `spec/requests/eager_loading_spec.rb`.
   * Decisions confirmed 2026-10-12 (Block 9 gate):
     * Routes `/recipes/browse/cuisine` and `/recipes/browse/food-type`.
     * Browse card: image or Cuisine flag badge, Language flag by the title, "Filed Under:
       Cuisine » Food Type", then Chef | Created | Reactions | Comments, plus Serves/Makes
       and Cook Time when filled in. No teaser (Description is usually blank).
     * Basic filter: Cuisine, Food Type, Language, Chef, Created, Published.
     * SQL fields: cuisine, food_type, language, title, chef, cook_time, created, portions,
       serves, makes, comments, reactions (Chronicle's `smiles`, renamed), published.
     * Results table: Cuisine | Food Type | Title | Chef | Created | Published | Reactions.
     * Left nav: Recipes (Browse By Cuisine, Browse By Food Type, Filter) and My Recipes
       (My Published / My Draft, as Filter links). The three pages join the Start Page choices.
     * `return_to` on every link into a recipe; with none, Back falls back to Browse By
       Cuisine.
10. **Find Recipes By Ingredients**: enter e.g. Chicken, Garlic, Cream and watch the result
    count drop as each ingredient is added. Requested 2026-10-12.
11. **Download Recipes**: a Filter-style page with CSV and PDF-ZIP downloads, reusing
    `PdfRenderingService`/`ZipBundlingService`.
12. **Full Left Nav wiring + Toasts** (`to_toast_label` on Recipe, Cuisine, FoodType and Language)
    and **User Guide pages** for Cookbook.
* Later block: link each Cuisine/Food Type show page to its Browse leaf.
* Explicitly out of scope: **Import Recipes** (deferred, see Decisions 2026-10-11) and the
  `return_to` retrofit for Chronicle and Occasions (a separate follow-up PR).

## Cleanup
* Update this document with all decisions during the development
* Move the document to Archived once everything else is done
* All updated files for example 'Feature_-_Style.md' to be added to git if they are not yet version controlled 

  




