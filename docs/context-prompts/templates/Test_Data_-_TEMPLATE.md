# TASK
* Generate test data for [APP / MODEL(S)] to support manual testing of [FEATURE / SCENARIO].
* This is for manual/exploratory testing in a local dev database — not FactoryBot factories for
  the automated suite (those live under `spec/factories/` and should already exist or be added
  there separately if the feature needs new ones).

---

# SCOPE
* Target app/model(s): [e.g. Recipes — Recipe, Ingredient, Category]
* Quantity: [e.g. 20 recipes, spread across all categories]
* Owner(s)/author(s) to attach records to: [existing persona(s), or "create N new users"]

---

# REALISM CONSTRAINTS
* Naming: [real-sounding names vs. "Test Recipe 1" placeholders]
* Distribution: [e.g. spread evenly across categories / weighted toward one category to test a
  specific filter or pagination edge]
* Dates: [spread over what range — created_at/updated_at relevant to any date-based
  sorting/filtering being tested]
* Classification mix, if applicable: [restricted / contacts / unrestricted split]
* Content length/format: [short vs. long bodies, with/without images, Raw vs. Formatted]

---

# GENERATION METHOD
* [ ] `bin/rails console` script (one-off, not committed)
* [ ] `db/seeds.rb` addition (if this should be repeatable/shared)
* [ ] Import via existing `ImportService`/CSV, if the app supports it

---

# CLEANUP
* [How to remove this data afterward — e.g. "all records tagged with a distinguishing marker,
  delete by that", or "db:reset is fine, nothing else in dev db to preserve"]

---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while generating data.)*
*
