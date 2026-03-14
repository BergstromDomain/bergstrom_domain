# Blog Post 1 — Getting Started with Rails

## Introduction

This post begins a long-term journey: building my personal website **bergstromdomain.com** using **Ruby on Rails**.

The goal of the site is to host several applications that I use in everyday life, including:

* Lifestyle Event Tracker
* Blog platform
* Photo album manager
* Training logs
* Recipes
* Wine cellar manager
* Resume/CV page
* Social media parser

In this series I will document the full development journey, including architecture decisions, testing approaches, and lessons learned.

The first application I will build is the **Lifestyle Event Tracker**, which will allow users to track birthdays, concerts, anniversaries, sporting events and other life milestones.

But before building features, we need to set up a **clean Rails development environment**.

This article covers:

* Installing Rails on Ubuntu
* Creating the Rails application
* Setting up PostgreSQL
* Adding a proper testing stack
* Adding code quality tools
* Managing secrets safely
* Structuring commits

All development will follow a **Test Driven Development (TDD)** workflow.

---

# Development Environment

The development stack for this project is:

| Tool            | Version                    |
| --------------- | -------------------------- |
| Ruby            | 4.x                        |
| Rails           | 8.x                        |
| Database        | PostgreSQL                 |
| Testing         | RSpec + Capybara           |
| Factories       | FactoryBot                 |
| Coverage        | SimpleCov                  |
| Linting         | RuboCop                    |
| Security        | Brakeman                   |
| Performance     | Bullet                     |
| Secrets         | Rails Credentials + dotenv |
| Version Control | Git + GitHub               |

Development will be done on **Ubuntu Linux** using a native setup rather than Docker.

---

# Step 1 — Create Project Folder

Create a directory for the project.

```bash
mkdir -p ~/projects
cd ~/projects
```

---

# Step 2 — Install Rails

Install Rails globally.

```bash
gem install rails
```

Verify installation.

```bash
rails -v
```

Expected output:

```
Rails 8.x.x
```

---

# Step 3 — Create the Rails Application

Generate the new Rails project.

```bash
rails new bergstrom_domain -d postgresql -T
```

Explanation:

```
-d postgresql
```

configures PostgreSQL as the default database.

```
-T
```

disables the default Rails **Minitest** framework because we will use **RSpec**.

Enter the project directory.

```bash
cd bergstrom_domain
```

---

# Step 4 — Initialize Git

Initialize the repository.

```bash
git init
git add .
git commit -m "Initial Rails 8 project setup for bergstrom_domain"
```

---

# Step 5 — Configure PostgreSQL

Rails manages the database automatically.

Create the database.

```bash
rails db:create
```

Run migrations.

```bash
rails db:migrate
```

Verify the server runs.

```bash
rails server
```

Open a browser.

```
http://localhost:3000
```

You should see the Rails welcome page.

---

# Step 6 — Add Testing Framework

Add testing gems to the **Gemfile**.

```ruby
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "capybara"
  gem "simplecov", require: false
end
```

Install dependencies.

```bash
bundle install
```

Generate RSpec configuration.

```bash
rails generate rspec:install
```

This creates:

```
spec/
spec/spec_helper.rb
spec/rails_helper.rb
```

Commit the changes.

```bash
git add .
git commit -m "Add RSpec, FactoryBot and Capybara for testing"
```

---

# Step 7 — Configure Code Quality Tools

Add development quality tools.

Update the **Gemfile**.

```ruby
group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "brakeman", require: false
  gem "bullet"
end
```

Install dependencies.

```bash
bundle install
```

Generate RuboCop configuration.

```bash
bundle exec rubocop --auto-gen-config
```

Fix autocorrectable issues.

```bash
bundle exec rubocop -A
```

Run security scanning.

```bash
bundle exec brakeman
```

Commit the changes.

```bash
git add .
git commit -m "Add Rubocop, Brakeman and Bullet for code quality"
```

---

# Step 8 — Manage Secrets with dotenv

Secrets should never be stored in the repository.

Add dotenv to the **Gemfile**.

```ruby
group :development, :test do
  gem "dotenv-rails"
end
```

Install the gem.

```bash
bundle install
```

Create the environment file.

```
.env
```

Example:

```
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=secretpassword
```

Ignore this file in git.

Edit:

```
.gitignore
```

Add:

```
.env
```

Commit the configuration.

```bash
git add .
git commit -m "Add dotenv for environment variable management"
```

---

# Step 9 — Rails Encrypted Credentials

Rails also supports encrypted credentials.

Open the credentials editor.

```bash
EDITOR=nano rails credentials:edit
```

Example structure:

```yaml
database:
  username: postgres
  password: examplepassword
```

Rails stores encrypted secrets in:

```
config/credentials.yml.enc
```

Commit the encrypted file.

```bash
git add .
git commit -m "Configure Rails encrypted credentials"
```

---

# Step 10 — Create Documentation Structure

Because the blog application does not exist yet, these articles will be written locally.

Create a documentation folder.

```bash
mkdir -p docs/blog
```

Create the first article.

```
docs/blog/001-getting-started-with-rails.md
```

Commit it.

```bash
git add .
git commit -m "Add documentation structure for blog posts"
```

---

# Step 11 — Verify the Environment

Run the following checks.

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
rails server
```

All commands should run without errors.

---

# Deep Dive — Why These Tools?

## Test Driven Development

TDD encourages writing tests before implementation.

Benefits include:

* fewer regressions
* clearer design
* safer refactoring

RSpec and Capybara provide a powerful Rails testing stack.

---

## PostgreSQL

PostgreSQL was chosen because it offers:

* strong data integrity
* powerful indexing
* excellent JSON support
* production-grade reliability

Most large Rails applications use PostgreSQL.

---

## RuboCop

RuboCop enforces consistent code style and prevents common Ruby mistakes.

This improves:

* code readability
* maintainability
* team collaboration

---

## Secrets Management

Storing secrets in Git repositories is dangerous.

Two strategies are used here:

### dotenv

Simple local environment variables.

### Rails credentials

Encrypted configuration built into Rails.

Using both demonstrates real-world approaches.

---

# Git Commit History

At the end of this article the repository history should look like:

```
Initial Rails 8 project setup for bergstrom_domain
Configure PostgreSQL database
Add RSpec, FactoryBot and Capybara for testing
Add Rubocop, Brakeman and Bullet for code quality
Add dotenv for environment variable management
Configure Rails encrypted credentials
Add documentation structure for blog posts
```

---

# What's Next?

Now that the project foundation is ready, the next step is building the first real feature:

**The Lifestyle Event Tracker.**

The next article will cover:

* designing the **Person model**
* writing the first **RSpec tests**
* implementing the **People List View**
* creating **friendly URLs**
* generating **seed data using Metallica members**

Stay tuned for **Blog Post 2 — Designing the People Model**.
