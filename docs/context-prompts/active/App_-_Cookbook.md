#TASK
* Plan the development of 'Cookbook', a recepies app to be integrated into BergstromDomain
* Outline the main development blocks for developing the app. Before starting a new development block, summarise what you know and ask me to confirm and/or answer any design questions before progressing
* Follow previously TDD methodology with clear tests, keeping the test coverage above 95% and follow previously established guidelines

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
      * Dowload Recipies		Future improvement (empty link for now)
  H1 DOCUMENTATION			Add a TODO to the file 'Feature_-_Style.md' to update Occasions and Chronicle left nav to to add this H1
    H2 HOW TO				Add a TODO to the file 'Feature_-_Style.md' to update Occasions and Chronicle left nav to to add this H2
      * User Guide			Future improvement (empty link for now)

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
* After each edit, the recipie should be Draft

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
* **Likes**: Cookbook does **not** build interactive Likes yet. The `Like` model was hard-wired to
  `BlogPost` (not reusable as-is), so its rewrite was spun out into
  `docs/context-prompts/archive/Update_Feature_-_Likes.md`. Cookbook's Read-a-Recipe page ships
  with a static, non-interactive placeholder where Likes would go, until Cookbook itself picks
  this up.
  * **Confirmed 2026-09-19:** that rewrite's scope was the shared/polymorphic Like engine +
    Chronicle's retrofit only — it did not wire anything into Cookbook, since `Recipe` didn't
    exist yet.
  * **Ready to use as of 2026-09-19** (branch `feature/generalize-likes`, pending PR/merge): `Like`
    is now polymorphic (`belongs_to :likeable`) via the shared `Likeable` concern, so when
    Cookbook's Recipe Read block is built, it can `include Likeable` and swap the static
    placeholder for the real reaction row + breakdown popup — no further Likes-side work needed.
    Verify the branch has actually merged to `main` before relying on this.
* **Comments**: generalized to polymorphic (`belongs_to :commentable, polymorphic: true`,
  replacing `Comment`'s current `belongs_to :blog_post`) — shared by Chronicle and Cookbook now,
  and by future apps going forward, rather than duplicating a `RecipeComment` model. This is its
  own development block (touches Chronicle's existing model/specs), sequenced before Recipe's own
  Comments block below. Planning spun out into
  `docs/context-prompts/active/Update_Feature_-_Comments.md` (2026-09-19) — not paired with the
  Likes rewrite above, addressed as its own feature.
* **Ownership**: Recipe is single-owner only — no co-author shuttle like Chronicle's `BlogPost`
  (the app overview only ever says "his/hers recipe").

## DEVELOPMENT BLOCKS (confirmed order)
0. Foundation — `Recipe`/`Cuisine`/`FoodType`/`Language` models + migrations, routes, landing
   page, left-nav skeleton
1. Reference Data CRUD (Cuisine, Food Type, Language) — mirrors `EventTypesController`, plus the
   flag-emoji/icon-badge fields from Design Question-3
2. Generalize Comments to polymorphic (touches Chronicle's existing `Comment` model/specs) — see
   `Update_Feature_-_Comments.md`
3. Create a Recipe (Title/Description/Image frame, Metadata frame, Ingredients frame — new
   two-level dynamic add/remove rows, Description/body Raw-Formatted frame reusing
   Quill/`convert_format`, Action frame: Cancel | Save only)
4. Read a Recipe (Title/Metadata/Ingredients/Description/Comments/Action frames; Back button uses
   `return_to`; Likes = static placeholder)
5. Edit + Publish/Unpublish a Recipe (combined block, like Chronicle's; after each edit reverts to
   Draft)
6. Delete a Recipe (soft-delete, 30-day retention, admin restore — mirrors
   `PurgeDeletedBlogPostsJob`)
7. Comments (Recipe-specific wiring, mostly free once polymorphic)
8. Browse (by Cuisine, by Food Type — two separate single-level trees) + Filter (Basic/SQL,
   reusing `Jql::Parser`/`Jql::Evaluator` via a new `RecipeFilter` service)
9. Full Left Nav wiring + Toasts (`to_toast_label` on Recipe/Cuisine/FoodType/Language) +
   Cookbook Settings page (mirrors Chronicle/Occasions Settings)
* Explicitly out of scope for this plan: Likes (→ `Update_Feature_-_Likes.md`), collapsible/show-hide nav
  (→ `Feature_-_Collapsible_Navbar.md`), Download Recipes (doc's own "future improvement, empty
  link for now").

## Cleanup
* Update this document with all decisions during the development
* Move the document to Archived once everything else is done
* All updated files for example 'Feature_-_Style.md' to be added to git if they are not yet version controlled 

  




