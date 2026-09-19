# TASK
* Generate test data for Chronicle to support manual testing. I've spent some time reviewing the data and these categories are likely to be added as a post deployment step to PROD once we get there
* This is for manual/exploratory testing in a local dev database — not FactoryBot factories for
  the automated suite (those live under `spec/factories/` and should already exist or be added
  there separately if the feature needs new ones).

---

# SCOPE
* Create a 'System Admin' user with System Admin permissions in the DEV environment
* Delete any existing 'Blog Categories'
* Create the following 'Blog Categories' with the 'System Admin' as the author
| Name                    	| Lucide Icon Name |
| Arts & Culture		| palette
| Career & Work			| briefcase-business
| Cars & Transport		| car
| Education & Learning		| book-open
| Entertainment & Events	| drama
| Music & Audio			| music
| Family & Relationships	| hand-heart
| Finance & Money		| coins
| Food & Drink			| chef-hat
| Friends & Social		| handshake
| Clothes & Fashion		| shirt
| Health & Wellbeing		| heart-pulse
| History			| landmark
| Hobbies & Interests		| puzzle
| Home & Garden			| house
| Nature & Environment		| trees
| News & Current Affairs	| newspaper
| Opinions & Ideas		| lightbulb
| Other				| shield-question-mark
| Personal			| venetian-mask
| Photography & Video		| camera
| Science			| atom
| Sport & Fitness		| bike
| Technology			| cpu
| Travel			| plane

* Given that the description field is mandatory, populate them all with "Posts about [Name]" and I will work on better descriptions before the PROD deployment

* I know that there is a lot left to do before the first PROD deployment but create a document to capture ideas/requirement for the PROD deployment
* The categories have been reviewed and are likely to be the once I want to create as a post deployment step, they should all br created by System Admin (and not have my name against them)
---

# REALISM CONSTRAINTS
N/A
---

# GENERATION METHOD
* [x] `bin/rails console` script (one-off, not committed)
* [ ] `db/seeds.rb` addition (if this should be repeatable/shared)
* [ ] Import via existing `ImportService`/CSV, if the app supports it

---

# CLEANUP
* N/A

---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while generating data.)*
* `BlogCategory` has no author/creator column at all (`id, name, description, icon, slug,
  created_at, updated_at` — confirmed via `bin/rails runner`), unlike `Person`/`Event` which have
  a real `user_id` owner plus `Auditable`'s `updater_id`. So "created by System Admin, not
  against my name" isn't something the schema can actually record either way — nothing shows
  authorship on a Blog Category in the UI. Ran the seed script as the existing System Admin user
  (`admin@bergstromdomain.com`, already `system_admin` role) as a procedural convention rather
  than a stored fact. Flagging in case this means Blog Categories should actually get a creator
  column later (e.g. for a future "who added this taxonomy entry" admin view).
* A "Create a System Admin user" step was in scope, but two already existed in dev
  (`admin@bergstromdomain.com` and the `Sam SysAdmin` persona `sam.sysadmin@example.com`) — no
  new user was created, the existing real admin account was reused.
* The 3 pre-existing Blog Categories (Technology/cpu, Travel/plane, Food/chef-hat) had blog posts
  attached (1, 1, and 3 posts respectively), and `BlogCategory` destroys are blocked
  (`dependent: :restrict_with_error`) while posts reference them. Reassigned those posts to the
  matching new category (Technology→Technology, Travel→Travel, Food→Food & Drink) before
  deleting the old rows, rather than leaving them uncategorized or blocking the deletion.
