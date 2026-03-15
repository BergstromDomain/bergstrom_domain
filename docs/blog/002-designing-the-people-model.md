# Designing the People Model

**File:** `docs/blog/002-designing-the-people-model.md`

---

# Blog Post 2 — Designing the People Model

## Introduction

In the previous article we created the foundation of the **bergstrom_domain** Rails application. The project now includes:

- Rails 8
- PostgreSQL
- RSpec testing
- FactoryBot
- Capybara
- Rubocop
- Brakeman
- Bullet
- SimpleCov
- dotenv
- Encrypted credentials

With the project infrastructure in place, we can begin implementing our first **domain model**.

The first module of the website will be the **Lifestyle Event Tracker**, which records important events in people's lives such as:

- Birthdays
- Weddings
- Concerts
- Graduations
- Anniversaries
- Deaths

Before we can store events, we need to represent the **people** those events belong to.

In this article we will:

- Design the `Person` model
- Use **Test Driven Development (TDD)** with RSpec
- Implement model validations
- Add a **virtual fullname attribute**
- Create a FactoryBot factory
- Run migrations and tests
- Commit our changes to Git

By the end of this tutorial, the application will have a fully tested **Person model** ready to support future features.

---

# Step 1 — Generate the Person Model

We begin by generating a Rails model.

The `Person` model will eventually support:

- first name
- middle name
- last name
- description text
- thumbnail image
- full image

Run the Rails generator:

```bash
rails generate model Person firstname:string middlename:string lastname:string description:text thumbnail_image:string full_image:string