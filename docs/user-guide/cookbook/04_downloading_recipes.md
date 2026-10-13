---
title: Downloading Recipes
app_section: recipes
supports_guest: true
supports_user: true
supports_content_creator: true
---

## A single recipe

Every recipe's page has a **Download PDF** button. The PDF is laid out like a printed recipe: title, image, where it's filed, Serves or Makes and Cook Time, then the Description, Ingredients and Method. It leaves out comments and reactions.

## Download Recipes (Content Creator and above)

Choose **Actions › Import & Export › Download Recipes** in the left nav. Narrow the list with the same Basic or SQL filter as *Finding Recipes*, then:

- **Download PDFs**: a ZIP file with one PDF per recipe, named after its title (a repeated title gets `_2`). You're asked to confirm how many recipes it will include.
- **Download CSV**: one row per recipe, for a spreadsheet.

Both download the recipes in the order shown in the table, and only recipes you're allowed to see. Files are named `BergstromDomain_Cookbook_` followed by the date.

### CSV columns

Title, Cuisine, Food Type, Language, Chef, Created, Published, Serves, Makes, Cook Time, Description, Ingredients and Method (Markdown).

- Two Cuisines or Food Types share a cell: "Swedish · Italian".
- Ingredients has one line per ingredient ("1 tbsp Butter, softened"), with each list's heading on its own line above its ingredients.

Importing recipes isn't available yet.
