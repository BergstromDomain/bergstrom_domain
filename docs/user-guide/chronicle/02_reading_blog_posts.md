---
title: Reading Blog Posts
app_section: blog_posts
supports_guest: true
supports_user: true
supports_content_creator: true
---

There are two ways to find a post, both under **Blog Posts** in the left nav. Each only shows posts you're allowed to see.

## Browse Blog Posts

Starts with every Category and the number of posts in it. Categories that have posts are shown in bold; the others are listed too, with a count of 0.

Choose a Category to see its posts, newest first, along with the Subjects inside it. Choose a Subject to narrow to its posts and Topics, and a Topic to narrow once more. At the last level a breadcrumb takes you back up.

Each card shows the post's image (or its Category's icon), title, where it's filed, its author, when it was created, its reaction score, how many comments it has and the first few lines of the post.

## Filter Blog Posts

Narrows the list with a table you can sort by clicking its column headers.

**Basic** offers dropdowns for Category, Subject, Topic, Author, Created (Today, This Week, This Month or This Year) and Published (All, Published Only or Drafts Only). Choices are combined with AND.

**SQL** lets you write a query, for example:

```
category = "Technology" AND (topic = "Ruby On Rails" OR comments > 5)
```

| Field | Example |
| --- | --- |
| `category`, `subject`, `topic` | `subject = "Ruby On Rails"` |
| `title`, `author` | `title CONTAINS "rails"` |
| `created` | `created >= "2026-01-01"` |
| `comments` | `comments > 5` |
| `smiles` (the reaction score) | `smiles >= 4` |
| `published` | `published = "false"` |

Combine conditions with `AND`, `OR` and brackets. `=`, `!=` and `CONTAINS` compare text without regard to case. `author` is the post's main author.

**My Published Posts** and **My Draft Posts** in the left nav open Filter Blog Posts already narrowed to posts where you're the main author.

## Reading a post

A post's page shows its image, Category, Subject and Topic, authors, comment count and reactions, then the post itself. **Download PDF** saves a copy laid out for printing.

## Reactions and Comments

Signed in, you can react to a post with one of five faces, from angry to grinning, and change or clear it later. The post's score is the average of everyone's reactions. You can also comment, and reply to comments. You can edit or delete your own comments.
