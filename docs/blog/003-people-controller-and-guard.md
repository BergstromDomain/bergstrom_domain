# Blog Post 3 — People Controller, Index Page, and Guard

**File:** `docs/blog/003-people-controller-and-guard.md`

---

# Building the People Controller, Index Page, and Setting Up Guard

In the previous article we created the **Person model**, including:

- Slug based URLs
- Search scopes
- Image helpers
- RSpec model tests
- FactoryBot factories

At this point we have a solid **data layer**, but our application still has **no interface for users to view people**.

In this article we will build the first **user-facing feature** of the site.

We will implement:

- A **People controller**
- A **People index page**
- A **Person show page**
- **Friendly URLs using slugs**
- **Seed data** using members of Metallica
- **System tests** with Capybara
- **Guard** to automatically run tests and Rubocop while we code

By the end of this article you will be able to visit:
