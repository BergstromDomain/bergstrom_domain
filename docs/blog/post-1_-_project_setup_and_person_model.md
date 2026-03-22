# Building bergstromdomain.com — Post #1: Project Setup & The Person Model

**Series:** Building My Personal Website with Ruby on Rails
**Date:** March 2026
**Author:** Niklas Bergstrom

---

## Welcome to the Journey

This is the first post in what I expect to be a long series documenting the complete development of [bergstromdomain.com](https://bergstromdomain.com) — my personal website built from scratch using Ruby on Rails.

The goal is not just to ship a site, but to do it *properly*: with clean architecture, a disciplined Test Driven Development (TDD) workflow, and full transparency about every decision made along the way. If you're learning Rails, following TDD practices, or building something similar, I hope this series saves you hours of trial and error.

This post is honest. I started development before writing it, ran into a series of real issues, tore everything back to a clean slate, and rebuilt it properly. Every problem and fix is documented below exactly as it happened.

---

## What Are We Building?

The site will eventually host several real-world applications I use in my day-to-day life:

- **Event Tracker** — milestones for me, my family, and friends
- **Blog Posts** — this series and more
- **Recipes** — a personal cookbook
- **Resume** — professional profile
- **Photo Album** — memories

We're starting with the **Event Tracker**, which will track important milestones across categories like Birthdays, Education, Work, Sport, Weddings, and Music. At the heart of it is the `Person` model — the very first piece of the application we'll build and test today.

---

## The Development Stack

| Tool | Version |
|---|---|
| OS | Ubuntu 24.04.4 LTS (native, no Docker) |
| Ruby | 4.0.0 |
| Rails | 8.1.2 |
| Database | PostgreSQL |
| Testing | RSpec + Capybara |
| Factories | FactoryBot |
| Coverage | SimpleCov |
| Linting | RuboCop + rubocop-rails-omakase |
| Security | Brakeman |
| Performance | Bullet |
| Secrets | Rails Credentials + dotenv |
| Version Control | Git + GitHub |

No Docker. Everything runs natively. This keeps the feedback loop fast and the setup transparent.

---

## Phase 1: System Prerequisites

Before touching Rails, make sure your Ubuntu system is ready. Install ALL build dependencies first — missing any of these causes Ruby's native C extensions to fail to compile, which leads to subtle downstream problems.

### 1.1 Install System Dependencies

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  curl wget git build-essential \
  libssl-dev libreadline-dev zlib1g-dev \
  libffi-dev libyaml-dev libgdbm-dev \
  libncurses5-dev libpq-dev \
  libgmp-dev libdb-dev libxslt1-dev \
  libxml2-dev libc6-dev autoconf \
  postgresql postgresql-contrib \
  imagemagick libvips42
```

> **Why so many dependencies?** Ruby compiles native C extensions for gems like `psych`, `stringio`, `io-console`, and `date`. If the build libraries aren't present when Ruby is installed, those extensions silently fail and you'll see warnings like `ignoring because it is missing extensions` during `bundle install`. Install everything upfront and you avoid this entirely.

### 1.2 Install rbenv and Ruby 4.x

```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add rbenv to shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 4.0.0
rbenv install 4.0.0
rbenv global 4.0.0

ruby -v   # Confirm version
```

### 1.3 Install Bundler and Rails

Install Bundler explicitly before Rails. Ruby ships with a default Bundler gem baked in, and if you've reinstalled Ruby you may end up with two Bundler versions causing this warning:

```
The running version of Bundler (4.0.8) does not match the version of the
specification installed for it (4.0.3).
```

The default gem (4.0.3) cannot be uninstalled — it is baked into the Ruby installation. The fix is to install the newer version explicitly and pin it:

```bash
gem install bundler -v '4.0.8'
rbenv rehash
bundler --version   # Should show 4.0.8
```

Now install Rails:

```bash
gem install rails -v '~> 8.1'
rails -v   # Confirm version
```

### 1.4 Configure PostgreSQL

```bash
sudo -u postgres psql

-- Inside psql:
CREATE USER bergstrom WITH PASSWORD 'your_secure_password' CREATEDB;
\q
```

---

## Phase 2: Create the Rails Application

```bash
rails new bergstrom_domain \
  --database=postgresql \
  --skip-test

cd bergstrom_domain
```

> Note the app name uses an underscore (`bergstrom_domain`), which means Rails will create databases named `bergstrom_domain_development` and `bergstrom_domain_test`. Keep this consistent throughout.

### 2.1 Configure the Database

Edit `config/database.yml`:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: bergstrom
  password: <%= ENV["DB_PASSWORD"] %>
  host: localhost

development:
  <<: *default
  database: bergstrom_domain_development

test:
  <<: *default
  database: bergstrom_domain_test

production:
  <<: *default
  database: bergstrom_domain_production
  username: bergstrom
  password: <%= ENV["DB_PASSWORD"] %>
```

Create a `.env` file (never commit this):

```bash
echo "DB_PASSWORD=your_secure_password" > .env
echo ".env" >> .gitignore
```

Create the databases:

```bash
rails db:create
```

### 2.2 Initialise Git

```bash
git init
git add .
git commit -m "Initial Rails application scaffold"
```

Create a repository on GitHub, then:

```bash
git remote add origin git@github.com:yourusername/bergstrom_domain.git
git push -u origin main
```

---

## Phase 3: Configure the Test & Tooling Stack

### 3.1 Gemfile

Here is the complete Gemfile including both the Rails defaults and the full testing/tooling stack:

```ruby
source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "dotenv-rails"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop", require: false
  gem "brakeman", require: false
  gem "bullet"
  gem "pry-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "guard"
  gem "guard-rspec"
  gem "guard-rubocop"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end
```

Install:

```bash
bundle install
```

> **Note on Solid Queue:** You may see `Upgrading from Solid Queue < 1.0? Check details on breaking changes` during `bundle install`. This only applies to existing apps upgrading from an older version. Since this is a new app, ignore it completely.

### 3.2 Install RSpec

```bash
rails generate rspec:install
```

This creates `.rspec`, `spec/spec_helper.rb`, and `spec/rails_helper.rb`.

### 3.3 Configure spec/rails_helper.rb

> **Critical:** SimpleCov must be required at the very top of the file, before any application code is loaded. If it loads after `config/environment`, it misses coverage on already-loaded files and the report will be inaccurate.

```ruby
# spec/rails_helper.rb

# SimpleCov — must be loaded first, before any application code
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/spec/"
  add_filter "/config/"
  # Exclude Rails boilerplate not yet in use
  add_filter "app/jobs/application_job.rb"
  add_filter "app/mailers/application_mailer.rb"
  # Only enforce coverage threshold on full suite runs
  minimum_coverage 90 if ENV["COVERAGE"]
end

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"
require "shoulda/matchers"
require "database_cleaner/active_record"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Database Cleaner
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }
  config.before(:each)  { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }
  config.before(:each)  { DatabaseCleaner.start }
  config.after(:each)   { DatabaseCleaner.clean }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

> **Why `minimum_coverage 90 if ENV["COVERAGE"]`?** Running only model specs reports ~27% coverage because the feature specs haven't exercised the controllers and views yet. Gating the threshold behind an environment variable means coverage is only enforced on a full suite run (`COVERAGE=true bundle exec rspec`), not when running a subset of specs during development.

### 3.4 Configure Bullet (N+1 Detection)

In `config/environments/development.rb`, inside the `Rails.application.configure do` block:

```ruby
Rails.application.configure do
  # ... existing Rails config ...

  # N+1 query detection
  config.after_initialize do
    Bullet.enable       = true
    Bullet.alert        = true
    Bullet.rails_logger = true
    Bullet.add_footer   = true
  end
end
```

> **Important:** `config.after_initialize` must be inside `Rails.application.configure do`. Placing it outside raises a `NoMethodError`.

### 3.5 Configure RuboCop

`rubocop-rails-omakase` is a pure config preset — it contains only a `rubocop.yml` file and no Ruby code. This means it cannot be `require`d or used as a `plugins` entry directly. It must be loaded via `inherit_gem`.

Create `.rubocop.yml`:

```yaml
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

inherit_mode:
  merge:
    - Exclude

AllCops:
  NewCops: enable
  Exclude:
    - "db/schema.rb"
    - "bin/**/*"
    - "vendor/**/*"
    - "node_modules/**/*"
```

Verify it works:

```bash
bundle exec rubocop --autocorrect-all
```

Commit the tooling setup:

```bash
git add .
git commit -m "Add RSpec, FactoryBot, Capybara, SimpleCov, RuboCop, Brakeman, Bullet"
```

---

## Phase 4: The Person Model — TDD from the Ground Up

The `Person` model is the foundation of the Event Tracker. Every event belongs to a person.

### Model Requirements

- `first_name` — string, **mandatory**
- `middle_name` — string, optional
- `last_name` — string, optional
- `description` — text, optional
- `thumbnail_image` — string (relative path under `app/assets/images/`)
- `full_image` — string (relative path under `app/assets/images/`)
- `full_name` — **virtual attribute** (not stored in DB), computed as `"first_name middle_name last_name"` with blanks stripped, must be **unique** across all records

### Image Storage Strategy (Local Development)

Images are stored under `app/assets/images/` and served through the Propshaft asset pipeline. This is important — files placed in `public/` are **not** in Propshaft's load path and will raise `Propshaft::MissingAssetError` when referenced via `image_tag`.

The folder structure:

```
app/assets/images/
  people/
    full/
      james_hetfield.jpg
      lars_ulrich.jpg
      kirk_hammett.jpg
      robert_trujillo.jpg
    thumbnails/
      james_hetfield_thumb.jpg
      lars_ulrich_thumb.jpg
      kirk_hammett_thumb.jpg
      robert_trujillo_thumb.jpg
```

Paths stored in the database are relative to `app/assets/images/`, e.g. `"people/full/james_hetfield.jpg"`.

Create placeholder images for development using ImageMagick:

```bash
mkdir -p app/assets/images/people/full
mkdir -p app/assets/images/people/thumbnails

convert -size 400x400 xc:lightgray app/assets/images/people/full/james_hetfield.jpg
convert -size 400x400 xc:lightgray app/assets/images/people/full/lars_ulrich.jpg
convert -size 400x400 xc:lightgray app/assets/images/people/full/kirk_hammett.jpg
convert -size 400x400 xc:lightgray app/assets/images/people/full/robert_trujillo.jpg

convert -size 100x100 xc:lightgray app/assets/images/people/thumbnails/james_hetfield_thumb.jpg
convert -size 100x100 xc:lightgray app/assets/images/people/thumbnails/lars_ulrich_thumb.jpg
convert -size 100x100 xc:lightgray app/assets/images/people/thumbnails/kirk_hammett_thumb.jpg
convert -size 100x100 xc:lightgray app/assets/images/people/thumbnails/robert_trujillo_thumb.jpg
```

> When the app moves to a server, this strategy will be replaced with Active Storage (local disk, S3, or similar) and the string columns will become Active Storage attachments.

---

## Phase 5: Write the Model Spec First (Red → Green → Refactor)

Test data throughout this project uses the members of Metallica. It makes the specs more readable and memorable than generic placeholder names.

### spec/models/person_spec.rb

```ruby
# spec/models/person_spec.rb

require "rails_helper"

RSpec.describe Person, type: :model do
  subject(:person) { build(:person, :james_hetfield) }

  # ── Database columns ─────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:middle_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:thumbnail_image).of_type(:string) }
    it { is_expected.to have_db_column(:full_image).of_type(:string) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }

    context "full_name uniqueness" do
      it "is valid when full_name is unique" do
        create(:person, :james_hetfield)
        lars = build(:person, :lars_ulrich)
        expect(lars).to be_valid
      end

      it "is invalid when full_name already exists" do
        create(:person, :kirk_hammett)
        duplicate = build(:person, :kirk_hammett)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:base]).to include("Full name has already been taken")
      end

      it "treats nil middle name the same as blank" do
        create(:person, :lars_ulrich)
        duplicate = build(:person, first_name: "Lars", middle_name: "", last_name: "Ulrich")
        expect(duplicate).not_to be_valid
      end
    end
  end

  # ── Virtual attribute ─────────────────────────────────────────────────────
  describe "#full_name" do
    it "returns first and last name when no middle name" do
      lars = build(:person, :lars_ulrich)
      expect(lars.full_name).to eq("Lars Ulrich")
    end

    it "returns first middle and last name when all present" do
      james = build(:person, :james_hetfield)
      expect(james.full_name).to eq("James Alan Hetfield")
    end

    it "returns first middle and last name for all band members" do
      expect(build(:person, :james_hetfield).full_name).to eq("James Alan Hetfield")
      expect(build(:person, :lars_ulrich).full_name).to eq("Lars Ulrich")
      expect(build(:person, :kirk_hammett).full_name).to eq("Kirk Lee Hammett")
      expect(build(:person, :robert_trujillo).full_name).to eq("Robert George Trujillo")
    end

    it "returns only first name when middle and last are blank" do
      james = build(:person, first_name: "James", middle_name: nil, last_name: nil)
      expect(james.full_name).to eq("James")
    end

    it "strips extra whitespace when middle name is blank" do
      james = build(:person, first_name: "James", middle_name: "", last_name: "Hetfield")
      expect(james.full_name).to eq("James Hetfield")
    end
  end
end
```

Run it — it should fail (Red):

```bash
bundle exec rspec spec/models/person_spec.rb --format documentation
```

Good. Now we make it pass.

---

## Phase 6: Generate the Migration

```bash
rails generate model Person \
  first_name:string \
  middle_name:string \
  last_name:string \
  description:text \
  thumbnail_image:string \
  full_image:string
```

Edit the generated migration to add the `null: false` constraint and composite index:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_people.rb

class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name
      t.text   :description
      t.string :thumbnail_image
      t.string :full_image

      t.timestamps
    end

    add_index :people, [:first_name, :middle_name, :last_name],
              name: "index_people_on_full_name"
  end
end
```

Run the migration for both environments:

```bash
rails db:migrate
rails db:migrate RAILS_ENV=test
```

> **If the test migration fails with `PG::DuplicateTable`**, the test database has a stale table from previous development. Fix with:
> ```bash
> rails db:drop RAILS_ENV=test
> rails db:create RAILS_ENV=test
> rails db:migrate RAILS_ENV=test
> ```

---

## Phase 7: Implement the Person Model

```ruby
# app/models/person.rb

class Person < ApplicationRecord
  before_validation :normalise_names

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [first_name, middle_name, last_name].reject(&:blank?).join(" ")
  end

  private

  def normalise_names
    self.middle_name = middle_name.presence
    self.last_name   = last_name.presence
  end

  def full_name_must_be_unique
    return if first_name.blank?

    scope = Person.where(
      first_name:  first_name.strip,
      middle_name: middle_name,
      last_name:   last_name
    )

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:base, "Full name has already been taken")
    end
  end
end
```

> **Why `before_validation :normalise_names`?** HTML forms submit empty strings (`""`) for blank fields, not `nil`. If your uniqueness validator queries `middle_name: nil`, it will not match a record stored with `middle_name: ""`. The `normalise_names` callback converts blank strings to `nil` before validation runs, ensuring the uniqueness check is consistent regardless of how the data arrived.

Run the model spec — it should now be Green:

```bash
bundle exec rspec spec/models/person_spec.rb --format documentation
```

---

## Phase 8: FactoryBot Factory

The factory uses Metallica band members as named traits. This makes specs self-documenting and avoids Faker-generated random middle names causing unexpected test failures.

```ruby
# spec/factories/people.rb

FactoryBot.define do
  factory :person do
    first_name      { Faker::Name.first_name }
    middle_name     { [Faker::Name.first_name, nil].sample }
    last_name       { Faker::Name.last_name }
    description     { Faker::Lorem.paragraph }
    thumbnail_image { nil }
    full_image      { nil }

    trait :first_name_only do
      middle_name { nil }
      last_name   { nil }
    end

    trait :complete do
      description     { Faker::Lorem.paragraph(sentence_count: 3) }
      thumbnail_image { "people/thumbnails/placeholder_thumbnail.png" }
      full_image      { "people/full/placeholder_full.png" }
    end

    trait :james_hetfield do
      first_name      { "James" }
      middle_name     { "Alan" }
      last_name       { "Hetfield" }
      description     { "Vocalist and rhythm guitarist, co-founder of Metallica." }
      thumbnail_image { "people/thumbnails/james_hetfield_thumb.jpg" }
      full_image      { "people/full/james_hetfield.jpg" }
    end

    trait :lars_ulrich do
      first_name      { "Lars" }
      middle_name     { nil }
      last_name       { "Ulrich" }
      description     { "Drummer and co-founder of Metallica." }
      thumbnail_image { "people/thumbnails/lars_ulrich_thumb.jpg" }
      full_image      { "people/full/lars_ulrich.jpg" }
    end

    trait :kirk_hammett do
      first_name      { "Kirk" }
      middle_name     { "Lee" }
      last_name       { "Hammett" }
      description     { "Lead guitarist of Metallica." }
      thumbnail_image { "people/thumbnails/kirk_hammett_thumb.jpg" }
      full_image      { "people/full/kirk_hammett.jpg" }
    end

    trait :robert_trujillo do
      first_name      { "Robert" }
      middle_name     { "George" }
      last_name       { "Trujillo" }
      description     { "Bassist of Metallica." }
      thumbnail_image { "people/thumbnails/robert_trujillo_thumb.jpg" }
      full_image      { "people/full/robert_trujillo.jpg" }
    end
  end
end
```

> **Lesson learned:** The base factory uses Faker which randomly assigns a middle name. Creating a person with `create(:person, first_name: "Lars", last_name: "Ulrich")` without `middle_name: nil` may produce `"Lars Hassan Ulrich"` — and your spec expecting `"Lars Ulrich"` will fail mysteriously. Always use the named traits, or always set `middle_name: nil` explicitly when using the base factory.

---

## Phase 9: Seed File

```ruby
# db/seeds.rb

people = [
  {
    first_name:      "James",
    middle_name:     "Alan",
    last_name:       "Hetfield",
    description:     "Vocalist and rhythm guitarist, co-founder of Metallica.",
    thumbnail_image: "people/thumbnails/james_hetfield_thumb.jpg",
    full_image:      "people/full/james_hetfield.jpg"
  },
  {
    first_name:      "Lars",
    middle_name:     nil,
    last_name:       "Ulrich",
    description:     "Drummer and co-founder of Metallica.",
    thumbnail_image: "people/thumbnails/lars_ulrich_thumb.jpg",
    full_image:      "people/full/lars_ulrich.jpg"
  },
  {
    first_name:      "Kirk",
    middle_name:     "Lee",
    last_name:       "Hammett",
    description:     "Lead guitarist of Metallica.",
    thumbnail_image: "people/thumbnails/kirk_hammett_thumb.jpg",
    full_image:      "people/full/kirk_hammett.jpg"
  },
  {
    first_name:      "Robert",
    middle_name:     "George",
    last_name:       "Trujillo",
    description:     "Bassist of Metallica.",
    thumbnail_image: "people/thumbnails/robert_trujillo_thumb.jpg",
    full_image:      "people/full/robert_trujillo.jpg"
  }
]

people.each do |attrs|
  Person.find_or_create_by!(
    first_name:  attrs[:first_name],
    middle_name: attrs[:middle_name],
    last_name:   attrs[:last_name]
  ) do |p|
    p.description     = attrs[:description]
    p.thumbnail_image = attrs[:thumbnail_image]
    p.full_image      = attrs[:full_image]
  end
end

puts "Seeded #{Person.count} people"
```

Run with:

```bash
rails db:seed
```

---

## Phase 10: Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :people

  root "people#index"
end
```

Verify all seven routes are present:

```bash
rails routes | grep people
```

---

## Phase 11: Generate Controller and Views

```bash
rails generate controller People index show new edit --no-helper --no-assets --force
```

> Use `--force` if a controller already exists from earlier development.

### app/controllers/people_controller.rb

```ruby
# app/controllers/people_controller.rb

class PeopleController < ApplicationController
  before_action :set_person, only: [:show, :edit, :update, :destroy]

  def index
    @people = Person.order(:last_name, :first_name)
  end

  def show; end

  def new
    @person = Person.new
  end

  def edit; end

  def create
    @person = Person.new(person_params)
    if @person.save
      redirect_to @person, notice: "Person was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: "Person was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: "Person was successfully deleted."
  end

  private

  def set_person
    @person = Person.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def person_params
    params.require(:person).permit(
      :first_name, :middle_name, :last_name,
      :description, :thumbnail_image, :full_image
    )
  end
end
```

### Views

**app/views/people/index.html.erb**
```erb
<h1>People</h1>

<% if @people.any? %>
  <div class="people-list">
    <% @people.each do |person| %>
      <%= render "person_card", person: person %>
    <% end %>
  </div>
<% else %>
  <p>No people found</p>
<% end %>

<%= link_to "Add Person", new_person_path %>
```

**app/views/people/show.html.erb**
```erb
<h1><%= @person.full_name %></h1>

<%= render "person_image", person: @person, size: :full %>

<% if @person.description.present? %>
  <p><%= @person.description %></p>
<% end %>

<%= link_to "Edit", edit_person_path(@person) %>
<%= link_to "Back to People", people_path %>
<%= button_to "Delete Person", person_path(@person), method: :delete,
    data: { confirm: "Are you sure you want to delete #{@person.full_name}?" } %>
```

**app/views/people/new.html.erb**
```erb
<h1>New Person</h1>
<%= render "form", person: @person %>
<%= link_to "Back to People", people_path %>
```

**app/views/people/edit.html.erb**
```erb
<h1>Edit <%= @person.full_name %></h1>
<%= render "form", person: @person %>
<%= link_to "Back", person_path(@person) %>
```

**app/views/people/_form.html.erb**
```erb
<%= form_with model: person do |form| %>
  <% if person.errors.any? %>
    <div class="error-messages">
      <ul>
        <% person.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :first_name %>
    <%= form.text_field :first_name %>
  </div>
  <div>
    <%= form.label :middle_name %>
    <%= form.text_field :middle_name %>
  </div>
  <div>
    <%= form.label :last_name %>
    <%= form.text_field :last_name %>
  </div>
  <div>
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>
  <div>
    <%= form.label :thumbnail_image %>
    <%= form.text_field :thumbnail_image %>
    <% if person.thumbnail_image.present? %>
      <%= image_tag person.thumbnail_image,
          alt: person.full_name, class: "person-image thumbnail" %>
    <% end %>
  </div>
  <div>
    <%= form.label :full_image %>
    <%= form.text_field :full_image %>
    <% if person.full_image.present? %>
      <%= image_tag person.full_image,
          alt: person.full_name, class: "person-image full" %>
    <% end %>
  </div>
  <div>
    <%= form.submit "Save Person" %>
  </div>
<% end %>
```

**app/views/people/_person_card.html.erb**
```erb
<div class="person-card">
  <%= link_to person_path(person) do %>
    <h2><%= person.full_name %></h2>
    <%= render "person_image", person: person, size: :thumbnail %>
  <% end %>
  <% if person.description.present? %>
    <p><%= truncate(person.description, length: 100) %></p>
  <% end %>
</div>
```

**app/views/people/_person_image.html.erb**
```erb
<% image_path = case size
                when :thumbnail then person.thumbnail_image.presence
                when :full      then person.full_image.presence
                end %>

<% if image_path.present? %>
  <%= image_tag image_path,
      alt:   person.full_name,
      class: "person-image #{size}" %>
<% end %>
```

> The partial only renders an image if a path is present. We don't fall back to a placeholder via `image_tag` — if the file doesn't exist in `app/assets/images/`, Propshaft raises `MissingAssetError`. Graceful omission is safer than a hard error.

---

## Phase 12: Feature Specs

### spec/features/people/create_person_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Create Person", type: :feature do
  context "with valid attributes" do
    it "creates a new person and redirects to their profile" do
      visit new_person_path

      fill_in "First name",  with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name",   with: "Hetfield"
      fill_in "Description", with: "Vocalist and rhythm guitarist, co-founder of Metallica."
      click_button "Save Person"

      expect(page).to have_current_path(person_path(Person.last))
      expect(page).to have_content("James Alan Hetfield")
      expect(page).to have_content("Person was successfully created.")
    end
  end

  context "with missing first name" do
    it "shows a validation error" do
      visit new_person_path
      fill_in "Last name", with: "Hetfield"
      click_button "Save Person"
      expect(page).to have_content("First name can't be blank")
    end
  end

  context "with a duplicate full name" do
    before { create(:person, :james_hetfield) }

    it "shows a uniqueness error" do
      visit new_person_path
      fill_in "First name",  with: "James"
      fill_in "Middle name", with: "Alan"
      fill_in "Last name",   with: "Hetfield"
      click_button "Save Person"
      expect(page).to have_content("Full name has already been taken")
    end
  end
end
```

### spec/features/people/list_people_spec.rb

```ruby
require "rails_helper"

RSpec.describe "List People", type: :feature do
  context "when no people exist" do
    it "shows an empty state message" do
      visit people_path
      expect(page).to have_content("No people found")
    end
  end

  context "when people exist" do
    let!(:james)  { create(:person, :james_hetfield) }
    let!(:lars)   { create(:person, :lars_ulrich) }
    let!(:kirk)   { create(:person, :kirk_hammett) }
    let!(:robert) { create(:person, :robert_trujillo) }

    it "displays all people" do
      visit people_path
      expect(page).to have_content("James Alan Hetfield")
      expect(page).to have_content("Lars Ulrich")
      expect(page).to have_content("Kirk Lee Hammett")
      expect(page).to have_content("Robert George Trujillo")
    end

    it "links to each person's profile" do
      visit people_path
      click_link "James Alan Hetfield"
      expect(page).to have_current_path(person_path(james))
    end

    it "shows a link to add a new person" do
      visit people_path
      expect(page).to have_link("Add Person", href: new_person_path)
    end
  end
end
```

### spec/features/people/show_person_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Show Person", type: :feature do
  let!(:person) { create(:person, :james_hetfield) }

  it "displays the person's full name" do
    visit person_path(person)
    expect(page).to have_content("James Alan Hetfield")
  end

  it "displays the description" do
    visit person_path(person)
    expect(page).to have_content("Vocalist and rhythm guitarist, co-founder of Metallica.")
  end

  it "has links to edit and go back to the list" do
    visit person_path(person)
    expect(page).to have_link("Edit")
    expect(page).to have_link("Back to People")
  end

  it "returns 404 for a non-existent person" do
    visit person_path(id: 99999)
    expect(page).to have_http_status(:not_found)
  end
end
```

### spec/features/people/edit_person_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Edit Person", type: :feature do
  let!(:person) do
    create(:person, first_name: "Robert", middle_name: "Agustin", last_name: "Trujillo")
  end

  it "updates the person's details" do
    visit edit_person_path(person)
    fill_in "Middle name", with: "Miguel"
    fill_in "Description", with: "Bassist of Metallica since 2003."
    click_button "Save Person"

    expect(page).to have_current_path(person_path(person))
    expect(page).to have_content("Robert Miguel Trujillo")
    expect(page).to have_content("Person was successfully updated.")
  end

  it "shows validation errors when first name is removed" do
    visit edit_person_path(person)
    fill_in "First name", with: ""
    click_button "Save Person"
    expect(page).to have_content("First name can't be blank")
  end

  context "when updating would create a duplicate full name" do
    before { create(:person, first_name: "Cliff", middle_name: nil, last_name: "Burton") }

    it "shows a uniqueness error" do
      visit edit_person_path(person)
      fill_in "First name",  with: "Cliff"
      fill_in "Middle name", with: ""
      fill_in "Last name",   with: "Burton"
      click_button "Save Person"
      expect(page).to have_content("Full name has already been taken")
    end
  end
end
```

> **Always set `middle_name: nil` explicitly in `before` blocks.** The base factory uses Faker. If you write `create(:person, first_name: "Cliff", last_name: "Burton")` without `middle_name: nil`, Faker assigns something like `"Cliff Rebekah Burton"`. The uniqueness query then looks for `middle_name: nil` and finds nothing — the update succeeds when it should fail.

### spec/features/people/delete_person_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Delete Person", type: :feature do
  let!(:person) { create(:person, :james_hetfield) }

  it "deletes the person and redirects to the list" do
    visit person_path(person)
    click_button "Delete Person"

    expect(page).to have_current_path(people_path)
    expect(page).to have_content("Person was successfully deleted.")
    expect(page).not_to have_content("James Alan Hetfield")
  end

  it "reduces the person count by 1" do
    expect {
      visit person_path(person)
      click_button "Delete Person"
    }.to change(Person, :count).by(-1)
  end
end
```

---

## Phase 13: Run the Full Suite

```bash
# Full suite
bundle exec rspec

# Full suite with coverage enforcement
COVERAGE=true bundle exec rspec

# Model specs only
bundle exec rspec spec/models/ --format documentation

# Feature specs only
bundle exec rspec spec/features/ --format documentation

# Security scan
bundle exec brakeman -q

# Linting
bundle exec rubocop --autocorrect-all
```

### Final Results

```
31 examples, 0 failures
Line Coverage: 100.0% (49 / 49)

Brakeman: 0 security warnings
RuboCop:  0 offenses
```

---

## Phase 14: Commit & Push

```bash
git add .
git commit -m "Person model complete — 31 examples, 0 failures, 100% coverage, 0 security warnings, 0 RuboCop offenses"
git push origin main
```

---

## Lessons Learned in Post #1

**1. Install ALL system build dependencies before installing Ruby.** Missing libraries cause Ruby's native C extensions to silently fail to compile. You'll see `ignoring because it is missing extensions` during `bundle install` and spend time chasing the wrong problem. The fix is to uninstall Ruby, install every `apt` dependency in the list above, then reinstall Ruby cleanly.

**2. SimpleCov must load before application code.** It belongs at the very top of `rails_helper.rb`, before `require_relative "../config/environment"`. If it loads after, it misses coverage on already-loaded files and your report is inaccurate.

**3. `rubocop-rails-omakase` is a config preset, not a plugin.** It contains only a `rubocop.yml` and must be loaded via `inherit_gem`. Using `require:` or `plugins:` raises `cannot load such file`. This is not obvious from the gem name or documentation.

**4. Propshaft only serves assets from `app/assets/`, not `public/`.** Storing images in `public/images/` and referencing them via `image_tag` raises `Propshaft::MissingAssetError`. Move images to `app/assets/images/` and store paths relative to that root.

**5. Normalise blank strings to `nil` before validation.** HTML forms submit `""` for empty fields, not `nil`. A uniqueness validator querying `middle_name: nil` will not match a record stored with `middle_name: ""`. A `before_validation` callback using `.presence` fixes this cleanly and consistently.

**6. Always set `middle_name: nil` explicitly in factories and before blocks.** The base factory uses Faker which randomly assigns middle names. A `before` block creating `"Cliff Burton"` without `middle_name: nil` may create `"Cliff Rebekah Burton"` — and your uniqueness check silently passes when it should fail. Named traits are the cleanest solution.

**7. Only enforce coverage thresholds on full suite runs.** Running model specs alone reports ~27% coverage because controllers and views are untouched. Gate the threshold behind `ENV["COVERAGE"]` to avoid false failures during development.

**8. Write the spec before the model.** Watching tests fail before the code exists makes requirements concrete. Edge cases like "what does `full_name` return when only `first_name` is present?" are answered by the spec, not discovered later in production.

**9. Old specs from initial development will haunt you.** If you're rebuilding from a clean slate, delete all spec files from the previous iteration before running the suite. Stale specs referencing old field names (`firstname` instead of `first_name`) or missing factories (`user`) will produce confusing failures that have nothing to do with your current code.

---

## What's Next

In **Post #2** we'll build the `Event` model and its relationship to `Person`. Each event will belong to a person and carry a category (Birthday, Education, Work, Sport, Wedding, Music), a date, and a description. We'll follow the same Red → Green → Refactor workflow.

Stay tuned — and if you spot anything I could do better, feel free to reach out.

---

*Bergstrom | bergstromdomain.com | Building in public, one commit at a time.*