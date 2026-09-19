# TASK
* Generate test data for Chronicle to support manual testing. 
* This is for manual/exploratory testing in a local dev database — not FactoryBot factories for
  the automated suite (those live under `spec/factories/` and should already exist or be added
  there separately if the feature needs new ones).

---

# SCOPE
* Create the following posts to test the applciation
* Isaac Newton
  * Approximately 500 words per post
  * Category: History
  * Author(s): Any Content Creator + a co-author
  * Data: 
    * Text 
    * Image(s)
    * Table - Listing his top 3 discoveries (Laws of Motion, Universal Gravitation, Calculus)
* Laws of Motion
  * Approximately 500 words per post
  * Category: Science
  * Author(s): Content Creator (same or different from Isaac Newton)
  * Data: 
    * Text 
    * Image(s)
    * Formula(s)
    * Link back to Isaac Newton (also update Isaac Newton to have a link to this post)
* Ruby on Rails
  * Approximately 500 words per post
  * Category: Technology
  * Author(s): Any Content Creator 
  * Data: 
    * Text 
    * Code snippets
    * Links to Github repos
* Getting better with Microsoft Office
  * Approximately 500 words per post
  * Category: Education & Learning
  * Author(s): Any Content Creator 
  * Data: 
    * Text 
    * Embedded Word/Excel/PowerPoint files, i.e. display the app icon and have the file as a downloadable attachment
* Learn to edit Insta360 videos
  * Approximately 500 words per post
  * Category: Photography & Video
  * Author(s): Any Content Creator 
  * Data: 
    * Text 
    * YouTube videos


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


---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while generating data.)*
*
