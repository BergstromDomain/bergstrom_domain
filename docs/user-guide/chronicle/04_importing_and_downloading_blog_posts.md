---
title: Importing And Downloading Blog Posts
app_section: blog_posts
supports_guest: false
supports_user: false
supports_content_creator: true
---

Content Creators and above can bring posts in from a file, and download them again. Both are under **Actions › Import & Export** in the left nav.

## Import Blog Posts

Imported posts are created as **Restricted drafts** under your name, so you can review, format and publish them afterwards. You can upload either of two kinds of file.

### A CSV file

One row per post, in the columns Title, Category, Subject, Topic and Body (Markdown). Choose **Download CSV Template** for a file with the right headings and one example row for each Blog Category.

- **Title** is required, and must be unique among your own posts.
- **Category** must match an existing Blog Category. Capitals don't matter.
- Each row is imported on its own, so a bad row doesn't stop the rest. Afterwards the page shows how many rows were imported and lists each failed row with its row number and the reason.

Most spreadsheet apps limit how much text a cell can hold, so a very long post may need trimming to fit the Body column.

### A ZIP file

Exactly one Markdown file (`.md` or `.markdown`), plus any images it uses. Choose the post's **Category** on the import page before uploading.

- The post's title is the Markdown file's name, with underscores turned into spaces. `My_Trip_To_Rome.md` becomes "My Trip To Rome".
- Images referenced from the Markdown by a path inside the ZIP, like `![Rome](images/rome.jpg)`, are kept in the post. PNG, JPEG and WebP images are supported.
- Subject and Topic aren't part of this format. Add them after importing.

Starting from a Word document? Look for a "Word to Markdown" converter that also exports the document's images, then zip the Markdown file and images together.

## Download Blog Posts

Narrow the list with the same Basic or SQL filter as *Reading Blog Posts*, then:

- **Download PDFs**: a ZIP file with one PDF per post, named after its title. You're asked to confirm how many posts it will include.
- **Download CSV**: one row per post, with the columns Title, Category, Subject, Topic, Author, Created, Published and Body (Markdown).
- **Download Full Export** (admins only): a ZIP file with a CSV that also has every author, the Visibility and the publish date, plus every post's images in an `images` folder.

Downloads only include posts you're allowed to see. Files are named `BergstromDomain_Chronicle_` followed by the date.
