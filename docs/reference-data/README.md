# Reference Data for PROD Deployment

This is the master list of "reference data" (the catalog-style records every app needs before
real content can be created against it — Event Types, Blog Categories, Social Media Platforms,
and future apps' equivalents like Cookbook's Cuisines/Food Types) that will need to exist in
PROD once BergstromDomain is deployed there.

**How this is meant to be used:**
* **During development**: you maintain this folder directly, editing/adding rows as reference
  data changes in dev — it doesn't need to be regenerated from the database each time.
* **At PROD deployment**: this folder becomes a post-deployment checklist. There is currently
  **no bulk-import path for these three reference-data types** (unlike People/Events, which
  have `ImportService`) — each row gets entered by hand through the app's own admin "Create"
  form (`New Event Type`, `New Blog Category`, `New Social Media Platform`, etc.), using this
  folder as the source list. If that's worth automating later (a CSV-import feature for
  reference data specifically), that's a separate feature to plan, not something this doc
  builds.
* **After that PROD deployment step is done**: this folder (and the note above) can be
  archived — see `docs/context-prompts/active/Feature_-_User_Guide.md`'s sibling convention in
  `docs_organization` for how this repo marks planning docs as historical once done.

## Format: one CSV per reference-data type, grouped by app

```
docs/reference-data/
├── README.md                              (this file)
├── occasions/
│   ├── event_types.csv
│   ├── social_media_platforms.csv
│   └── logos/                             (actual logo image files, referenced by
│                                            filename from social_media_platforms.csv's
│                                            "Logo Filename" column)
└── chronicle/
    └── blog_categories.csv
```

Each CSV opens directly in Excel/Numbers/Google Sheets/LibreOffice — no conversion needed, and
edits stay diffable in git (plain text), unlike a binary `.xlsx`/`.ods` workbook.

### Why this instead of the side-by-side single-sheet layout (Chronicle | Occasions | ... blocks)

Two real problems with putting every type side-by-side as columns in one sheet, not just a
style preference:

1. **Row counts differ a lot, and will differ more.** Today: Event Types (7 rows), Social Media
   Platforms (11), Blog Categories (25). Cookbook's Cuisines (30+) and Food Types (20+) will make
   this worse — a side-by-side layout forces every block's height to match the *tallest* block,
   leaving large ragged gaps under the shorter ones, and the gaps shift every time any one type's
   row count changes.
2. **The types don't actually share the same columns.** Blog Categories/Event Types are
   Name/Icon/Description, but Social Media Platforms is Name/**URL**/**Logo** (an uploaded image,
   not a Lucide icon name — it can't even be represented as a single spreadsheet cell, which is
   why logos live as real files in `occasions/logos/`, not inline data). A uniform 3-column
   block per type doesn't fit Social Media Platforms today, and there's no guarantee it'll fit
   whatever columns Cookbook's Cuisines/Food Types end up needing either.

One file per type sidesteps both: each grows downward independently regardless of row count, and
each can have exactly the columns that type actually needs.

**Adding a new reference-data type** (e.g. Cookbook's Cuisines): add a new CSV under that app's
subfolder (creating the subfolder if it's the app's first), header row = whatever columns that
type's model actually has (check the model, don't assume Name/Icon/Description — Social Media
Platform already breaks that assumption).

**Adding a new app**: add a new subfolder named after the app's brand (`cookbook/`, matching
`occasions/`/`chronicle/`), containing one CSV per reference-data type that app introduces.

## Current contents (extracted from dev, 2026-09-22)

| App | Type | File | Rows |
|---|---|---|---|
| Occasions | Event Types | `occasions/event_types.csv` | 7 |
| Occasions | Social Media Platforms | `occasions/social_media_platforms.csv` | 11 (+ 11 logo files) |
| Chronicle | Blog Categories | `chronicle/blog_categories.csv` | 25 |

**Worth a look before PROD**: every Blog Category's description is the same templated
`"Posts about <Name>"` — accurate today, but you may want real copy per category before this
list is actually used to seed PROD. Nothing else looked like a placeholder.
