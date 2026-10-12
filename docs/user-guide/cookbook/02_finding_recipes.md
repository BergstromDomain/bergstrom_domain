---
title: Finding Recipes
app_section: recipes
supports_guest: true
supports_user: true
supports_content_creator: true
---

There are four ways to find a recipe, all under **Recipes** in the left nav. Each only ever shows recipes you're allowed to see. When you open a recipe, its **Back** button returns you to the page you came from.

## Browse Recipes By Cuisine or Food Type

Lists every Cuisine (or Food Type) with the number of recipes in it, including those that have none yet. Choose one to see its recipes as cards, newest first.

A recipe can have up to two Cuisines and two Food Types, for example a Swedish lasagna filed under Swedish and Italian. It's counted, and shown, under each of them.

Each card shows the recipe's image (or its Cuisine's flag), its Language, where it's filed, the chef, when it was created, Serves or Makes, Cook Time, its reaction score and how many comments it has.

## Filter Recipes

Narrows the list with a table you can sort by clicking its column headers.

**Basic** offers dropdowns for Cuisine, Food Type, Language, Chef, Created and Published. Each dropdown only lists values that your visible recipes actually use, and choices are combined with AND.

**SQL** lets you write a query, for example:

```
cuisine = "Italian" AND ingredients CONTAINS "garlic" AND reactions >= 4
```

| Field | Example |
| --- | --- |
| `cuisine`, `food_type`, `language` | `cuisine = "Swedish"` |
| `title`, `chef`, `cook_time` | `title CONTAINS "soup"` |
| `ingredients` | `ingredients CONTAINS "cream"` |
| `created` | `created >= "2026-01-01"` |
| `portions`, `serves`, `makes` | `serves >= 4` |
| `comments`, `reactions` | `reactions >= 4` |
| `published` | `published = "false"` |

Combine conditions with `AND`, `OR` and brackets. `=`, `!=` and `CONTAINS` compare text without regard to case. A recipe with two Cuisines or Food Types, or several ingredients, matches when any of them does.

**My Published Recipes** and **My Draft Recipes** in the left nav open Filter Recipes already narrowed to your own recipes.

## Find Recipes By Ingredients

Type an ingredient and press **Enter** or a comma. It becomes a chip and the results update straight away. Add more to narrow the list, or remove a chip with its ×.

- A recipe matches when **every** ingredient appears somewhere in its ingredient list. "cream" matches "Sour cream" and "Cream cheese".
- Plurals are forgiven: "Tomatoes" finds "Tomato".
- Names are compared exactly as typed in each language. "Cream" won't find "grädde".
- The tally above the results shows how many recipes were left after each ingredient, for example `Chicken 14 → Garlic 9 → Cream 3`.
- Each card adds a **Matched** line with the recipe's own wording of what matched.

The search is part of the page address, so you can bookmark or share it.

## Reactions and Comments

Signed in, you can react to a recipe with one of five faces, from angry to grinning, and change or clear it later. The recipe's score is the average of everyone's reactions. You can also comment, and reply to comments. You can edit or delete your own comments.
