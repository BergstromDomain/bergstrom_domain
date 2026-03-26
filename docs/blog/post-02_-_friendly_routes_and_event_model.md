# Building bergstromdomain.com — Post #2: Friendly Routes & The Event Model

**Series:** Building My Personal Website with Ruby on Rails
**Date:** March 2026
**Author:** Bergstrom

---

## Welcome Back

In Post #1 we set up the full Rails stack, built the `Person` model with TDD, and shipped a working CRUD interface with feature specs. If you missed it, go back and read that one first — this post builds directly on top of it.

Today we have two goals:

1. **Add friendly URL routes to the `Person` model** — so people are accessed via `/people/james-hetfield` rather than `/people/42`.
2. **Build the `Event` model from scratch** — same Red → Green → Refactor discipline, same TDD workflow.

Let's get into it.

---

## Phase 1: Friendly Routes for the Person Model

Right now our `Person` routes look like `/people/1`, `/people/2`, etc. That's fine for a machine but not for a human. We want `/people/james-hetfield`. We'll use the `friendly_id` gem to make this happen with minimal fuss.

### 1.1 Add the Gem

```ruby
# Gemfile
gem "friendly_id", "~> 5.5"
```

```bash
bundle install
```

### 1.2 Generate the FriendlyId Slug Migration for Person

`friendly_id` stores slugs in a dedicated `slugs` table (when using the `:history` module, which we want so that old slugs redirect to the current one):

```bash
rails generate friendly_id
rails generate migration AddSlugToPeople slug:string:uniq
rails db:migrate
rails db:migrate RAILS_ENV=test
```

The first command generates `db/migrate/YYYYMMDDHHMMSS_create_friendly_id_slugs.rb` — the shared slugs history table. The second adds a `slug` column directly to `people` for fast lookup.

### 1.3 Update the Person Model

```ruby
# app/models/person.rb
class Person < ApplicationRecord
  extend FriendlyId
  friendly_id :full_name, use: [:slugged, :history]

  # ── Validations ──────────────────────────────────────────────────────────
  validates :first_name, presence: true
  validate  :full_name_must_be_unique

  # ── Virtual attribute ─────────────────────────────────────────────────────
  def full_name
    [first_name, middle_name, last_name].reject(&:blank?).join(" ")
  end

  # ── FriendlyId ───────────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    first_name_changed? || middle_name_changed? || last_name_changed? || super
  end

  private

  def full_name_must_be_unique
    return if first_name.blank?

    scope = Person.where(
      first_name:  first_name.strip,
      middle_name: middle_name.presence,
      last_name:   last_name.presence
    )

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      errors.add(:base, "Full name has already been taken")
    end
  end
end
```

The key additions are `extend FriendlyId`, the `friendly_id` declaration using `:full_name` as the slug candidate (our virtual attribute), and `should_generate_new_friendly_id?` so the slug regenerates when the name changes. Because `full_name` is a virtual attribute and not a real column, `full_name_changed?` doesn't exist — instead we check whether any of the three underlying columns (`first_name`, `middle_name`, `last_name`) changed, which covers every case where the slug would need to be different.

### 1.4 Update the PeopleController

Swap `Person.find` for `Person.friendly.find` so both slugs and numeric IDs resolve correctly (useful during development and for old bookmarked URLs):

```ruby
# app/controllers/people_controller.rb
private

def set_person
  @person = Person.friendly.find(params[:id])
rescue ActiveRecord::RecordNotFound
  render file: "#{Rails.root}/public/404.html", status: :not_found
end
```

### 1.5 Backfill Slugs on Existing Records

If you already have people in the database, run this once to generate slugs for them. The `&:save` shorthand breaks inside double-quoted shell strings, so use a heredoc or the Rails console instead:

```bash
# Option A — Rails console (simplest)
bin/rails console
> Person.find_each(&:save)

# Option B — inline script file
echo 'Person.find_each(&:save)' > /tmp/backfill_slugs.rb
bin/rails runner /tmp/backfill_slugs.rb
rm /tmp/backfill_slugs.rb
```

### 1.6 Update Person Model Spec

Add a slug column check and a spec for slug generation:

```ruby
# spec/models/person_spec.rb — add inside "database columns"
it { is_expected.to have_db_column(:slug).of_type(:string) }

# add a new describe block
describe "#slug" do
  it "generates a slug from full_name" do
    person = create(:person, first_name: "James", middle_name: nil, last_name: "Hetfield")
    expect(person.slug).to eq("james-hetfield")
  end

  it "regenerates the slug when the name changes" do
    person = create(:person, first_name: "James", last_name: "Hetfield")
    person.update!(last_name: "Newsted")
    expect(person.slug).to eq("james-newsted")
  end

  it "keeps the old slug resolvable after a name change" do
    person = create(:person, first_name: "James", last_name: "Hetfield")
    person.update!(last_name: "Newsted")
    expect(Person.friendly.find("james-hetfield")).to eq(person)
  end
end
```

### 1.7 Update Feature Specs for Friendly URLs

The path helpers still work without any changes (they use the record's `to_param`, which `friendly_id` overrides automatically). But it's worth adding an explicit check:

```ruby
# spec/features/people/show_person_spec.rb — add one new example
it "is accessible via a friendly URL" do
  visit "/people/anna-maria-bergstrom"
  expect(page).to have_content("Anna Maria Bergstrom")
end
```

### 1.8 Commit

```bash
git add .
git commit -m "Add friendly_id slugs to Person model"
```

---

## Phase 2: New Git Branch for the Event Model

We're building the `Event` model in isolation on its own branch. This keeps the main branch clean and makes the PR review focused.

```bash
git checkout -b feature/event-model
```

From here, every commit in this phase lands on `feature/event-model`. We'll merge to `main` at the end.

---

## Phase 3: Event Model Requirements

Before writing a single spec, let's be explicit about what we're building:

| Field | Type | Rules |
|---|---|---|
| `title` | string | Mandatory, unique |
| `description` | text | Optional |
| `day` | integer | Mandatory (1–31) |
| `month` | integer | Mandatory (1–12) |
| `year` | integer | Optional |
| `image` | string | Optional (file path / URL) |
| `thumbnail_image` | string | Optional (file path / URL) |

**Out of scope for this post (coming later):**
- Association to `Person` (`belongs_to :person`)
- Association to an `EventType` model

We'll stub those associations as comments in the model now so we don't forget.

---

## Phase 4: Write the Model Spec First (Red)

```bash
mkdir -p spec/models
```

### spec/models/event_spec.rb

```ruby
require "rails_helper"

RSpec.describe Event, type: :model do
  subject(:event) { build(:event) }

  # ── Associations (coming later) ───────────────────────────────────────────
  # belongs_to :person
  # belongs_to :event_type

  # ── Database columns ─────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:day).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:month).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:year).of_type(:integer) }
    it { is_expected.to have_db_column(:image).of_type(:string) }
    it { is_expected.to have_db_column(:thumbnail_image).of_type(:string) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  # ── Validations ──────────────────────────────────────────────────────────
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title).case_insensitive }

    it { is_expected.to validate_presence_of(:day) }
    it { is_expected.to validate_presence_of(:month) }

    it { is_expected.to validate_numericality_of(:day).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(31) }
    it { is_expected.to validate_numericality_of(:month).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12) }
    it { is_expected.to validate_numericality_of(:year).is_greater_than(0).allow_nil }

    context "title uniqueness" do
      it "is valid when title is unique" do
        create(:event, title: "Kill 'Em All")
        event = build(:event, title: "Ride the Lightning")
        expect(event).to be_valid
      end

      it "is invalid when title already exists" do
        create(:event, title: "Kill 'Em All")
        duplicate = build(:event, title: "Kill 'Em All")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:title]).to include("has already been taken")
      end

      it "is case-insensitive" do
        create(:event, title: "Kill 'Em All")
        duplicate = build(:event, title: "kill 'em all")
        expect(duplicate).not_to be_valid
      end
    end

    context "year is optional" do
      it "is valid without a year" do
        event = build(:event, year: nil)
        expect(event).to be_valid
      end
    end

    context "description is optional" do
      it "is valid without a description" do
        event = build(:event, description: nil)
        expect(event).to be_valid
      end
    end

    context "image fields are optional" do
      it "is valid without an image" do
        event = build(:event, image: nil, thumbnail_image: nil)
        expect(event).to be_valid
      end
    end
  end

  # ── #display_date ─────────────────────────────────────────────────────────
  describe "#display_date" do
    it "returns month/day when year is nil" do
      event = build(:event, day: 25, month: 5, year: nil)
      expect(event.display_date).to eq("25 May")
    end

    it "returns full date when year is present" do
      event = build(:event, day: 25, month: 5, year: 1983)
      expect(event.display_date).to eq("25 May 1983")
    end

    it "returns month name not month number" do
      event = build(:event, day: 1, month: 1, year: 2000)
      expect(event.display_date).to eq("1 Jan 2000")
    end
  end

  # ── #slug ─────────────────────────────────────────────────────────────────
  describe "#slug" do
    it "generates a slug from the title" do
      event = create(:event, title: "Kill 'Em All")
      expect(event.slug).to eq("kill-em-all")
    end

    it "regenerates the slug when the title changes" do
      event = create(:event, title: "Kill 'Em All")
      event.update!(title: "Ride the Lightning")
      expect(event.slug).to eq("ride-the-lightning")
    end

    it "keeps the old slug resolvable after a title change" do
      event = create(:event, title: "Kill 'Em All")
      event.update!(title: "Ride the Lightning")
      expect(Event.friendly.find("kill-em-all")).to eq(event)
    end
  end
end
```

Run the spec — it should **fail** (Red):

```bash
bundle exec rspec spec/models/event_spec.rb
```

Good. Now we build the thing.

---

## Phase 5: Generate the Migration

```bash
rails generate model Event \
  title:string \
  description:text \
  day:integer \
  month:integer \
  year:integer \
  image:string \
  thumbnail_image:string \
  slug:string
```

The generator only accepts `index` or `uniq` as a third token — `null:false` is not valid syntax there. Add the null constraints manually in the migration as shown below.

Edit the generated migration:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_events.rb
class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string  :title,           null: false
      t.text    :description
      t.integer :day,             null: false
      t.integer :month,           null: false
      t.integer :year
      t.string  :image
      t.string  :thumbnail_image
      t.string  :slug

      t.timestamps
    end

    add_index :events, :title, unique: true
    add_index :events, :slug,  unique: true
    add_index :events, [:month, :day],         name: "index_events_on_month_day"
    add_index :events, [:year, :month, :day],  name: "index_events_on_year_month_day"
  end
end
```

The `title` unique index enforces uniqueness at the database level. The composite date indexes will pay off once we're ordering and filtering events by date.

```bash
rails db:migrate
rails db:migrate RAILS_ENV=test
```

---

## Phase 6: Generate the FriendlyId Slug Migration for Event

```bash
rails generate migration AddFriendlyIdSlugsToEvents
```

No extra migration content needed — the shared `friendly_id_slugs` table was already created in Phase 1 when we ran `rails generate friendly_id`. The `slug` column on `events` is all we need.

---

## Phase 7: Implement the Event Model (Green)

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [:slugged, :history]

  # ── Associations (coming later) ───────────────────────────────────────────
  # belongs_to :person
  # belongs_to :event_type

  # ── Validations ──────────────────────────────────────────────────────────
  validates :title,  presence: true, uniqueness: { case_sensitive: false }
  validates :day,    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :month,  presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year,   numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # ── FriendlyId ───────────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    title_changed? || super
  end

  # ── Instance methods ──────────────────────────────────────────────────────
  def display_date
    month_name = Date::ABBR_MONTHNAMES[month]
    year? ? "#{day} #{month_name} #{year}" : "#{day} #{month_name}"
  end
end
```

Run the model spec:

```bash
bundle exec rspec spec/models/event_spec.rb
```

All green. Let's refactor.

### Refactor: Scopes

Add two named scopes we'll rely on in views and the seeds file:

```ruby
# app/models/event.rb — inside the class, after validations
scope :chronological,    -> { order(:year, :month, :day) }
scope :reverse_chrono,   -> { order(Arel.sql("year DESC NULLS LAST, month DESC, day DESC")) }
```

The `NULLS LAST` in `reverse_chrono` ensures events without a year sort after dated events rather than floating to the top.

---

## Phase 8: FactoryBot Factory

```ruby
# spec/factories/events.rb
FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Event #{n}" }
    description      { Faker::Lorem.paragraph }
    day              { rand(1..28) }
    month            { rand(1..12) }
    year             { [rand(1950..2025), nil].sample }
    image            { nil }
    thumbnail_image  { nil }

    trait :no_year do
      year { nil }
    end

    trait :dated do
      year { rand(1950..2025) }
    end

    trait :with_images do
      image           { "events/cover.jpg" }
      thumbnail_image { "events/thumb.jpg" }
    end
  end
end
```

---

## Phase 9: Generate the Controller, Routes & Views

```bash
rails generate controller Events index show new edit --no-helper --no-assets
```

### 9.1 routes.rb

Add friendly routes for both models:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :people
  resources :events
  root "people#index"
end
```

`friendly_id` integrates with Rails routing automatically — no changes to `resources :events` are needed. The slug becomes the `:id` segment in the URL.

### 9.2 app/controllers/events_controller.rb

```ruby
class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = Event.chronological
  end

  def show; end

  def new
    @event = Event.new
  end

  def edit; end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event was successfully deleted."
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :day, :month, :year,
      :image, :thumbnail_image
    )
  end
end
```

### 9.3 Views

**app/views/events/index.html.erb**
```erb
<h1>Events</h1>

<%= link_to "Add Event", new_event_path %>

<% if @events.empty? %>
  <p>No events found</p>
<% else %>
  <ul>
    <% @events.each do |event| %>
      <li>
        <%= link_to event.title, event_path(event) %>
        <span><%= event.display_date %></span>
      </li>
    <% end %>
  </ul>
<% end %>
```

**app/views/events/show.html.erb**
```erb
<h1><%= @event.title %></h1>
<p><%= @event.display_date %></p>
<% if @event.description.present? %>
  <p><%= @event.description %></p>
<% end %>

<%= link_to "Edit", edit_event_path(@event) %>
<%= link_to "Back to Events", events_path %>
<%= button_to "Delete Event", event_path(@event), method: :delete,
      data: { turbo_confirm: "Are you sure?" } %>
```

**app/views/events/new.html.erb**
```erb
<h1>New Event</h1>
<%= render "form", event: @event %>
<%= link_to "Back to Events", events_path %>
```

**app/views/events/edit.html.erb**
```erb
<h1>Edit Event</h1>
<%= render "form", event: @event %>
<%= link_to "Back to Events", events_path %>
```

**app/views/events/_form.html.erb**
```erb
<%= form_with model: event do |f| %>
  <% if event.errors.any? %>
    <div>
      <% event.errors.full_messages.each do |msg| %>
        <p><%= msg %></p>
      <% end %>
    </div>
  <% end %>

  <div>
    <%= f.label :title, "Title" %>
    <%= f.text_field :title %>
  </div>

  <div>
    <%= f.label :description, "Description" %>
    <%= f.text_area :description %>
  </div>

  <div>
    <%= f.label :day, "Day" %>
    <%= f.number_field :day %>
  </div>

  <div>
    <%= f.label :month, "Month" %>
    <%= f.number_field :month %>
  </div>

  <div>
    <%= f.label :year, "Year" %>
    <%= f.number_field :year %>
  </div>

  <div>
    <%= f.label :image, "Image" %>
    <%= f.text_field :image %>
  </div>

  <div>
    <%= f.label :thumbnail_image, "Thumbnail image" %>
    <%= f.text_field :thumbnail_image %>
  </div>

  <%= f.submit "Save Event" %>
<% end %>
```

---

### 9.4 Clean up generator stubs

The controller generator also creates request specs and view specs as empty stubs. Delete them — the feature specs cover everything they would test:

```bash
rm spec/requests/events_spec.rb
rm spec/views/events/edit.html.erb_spec.rb
rm spec/views/events/index.html.erb_spec.rb
rm spec/views/events/new.html.erb_spec.rb
rm spec/views/events/show.html.erb_spec.rb
```

```bash
mkdir -p spec/features/events
```

### 10.1 spec/features/events/create_event_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Create Event", type: :feature do
  context "with valid attributes" do
    it "creates a new event and redirects to its page" do
      visit new_event_path

      fill_in "Title",       with: "Kill 'Em All"
      fill_in "Description", with: "Metallica's debut studio album."
      fill_in "Day",         with: "25"
      fill_in "Month",       with: "7"
      fill_in "Year",        with: "1983"
      click_button "Save Event"

      expect(page).to have_current_path(event_path(Event.last))
      expect(page).to have_content("Kill 'Em All")
      expect(page).to have_content("Event was successfully created.")
    end
  end

  context "without a year" do
    it "is still valid" do
      visit new_event_path

      fill_in "Title", with: "Annual Tour"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "6"
      click_button "Save Event"

      expect(page).to have_content("Annual Tour")
      expect(page).to have_content("Event was successfully created.")
    end
  end

  context "with a missing title" do
    it "shows a validation error" do
      visit new_event_path

      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Save Event"

      expect(page).to have_content("Title can't be blank")
    end
  end

  context "with a missing day" do
    it "shows a validation error" do
      visit new_event_path

      fill_in "Title", with: "Orphaned Event"
      fill_in "Month", with: "6"
      click_button "Save Event"

      expect(page).to have_content("Day can't be blank")
    end
  end

  context "with a duplicate title" do
    before { create(:event, title: "Kill 'Em All", day: 25, month: 7, year: 1983) }

    it "shows a uniqueness error" do
      visit new_event_path

      fill_in "Title", with: "Kill 'Em All"
      fill_in "Day",   with: "1"
      fill_in "Month", with: "1"
      click_button "Save Event"

      expect(page).to have_content("Title has already been taken")
    end
  end
end
```

### 10.2 spec/features/events/list_events_spec.rb

```ruby
require "rails_helper"

RSpec.describe "List Events", type: :feature do
  context "when no events exist" do
    it "shows an empty state message" do
      visit events_path
      expect(page).to have_content("No events found")
    end
  end

  context "when events exist" do
    let!(:kill_em_all)      { create(:event, title: "Kill 'Em All",      day: 25, month: 7,  year: 1983) }
    let!(:ride_lightning)   { create(:event, title: "Ride the Lightning", day: 27, month: 7,  year: 1984) }
    let!(:master_puppets)   { create(:event, title: "Master of Puppets",  day: 3,  month: 3,  year: 1986) }

    it "displays all events" do
      visit events_path

      expect(page).to have_content("Kill 'Em All")
      expect(page).to have_content("Ride the Lightning")
      expect(page).to have_content("Master of Puppets")
    end

    it "links to each event's page" do
      visit events_path
      click_link "Kill 'Em All"
      expect(page).to have_current_path(event_path(kill_em_all))
    end

    it "displays events in chronological order" do
      visit events_path
      expect(page.text.index("Kill 'Em All")).to be < page.text.index("Ride the Lightning")
    end

    it "shows a link to add a new event" do
      visit events_path
      expect(page).to have_link("Add Event", href: new_event_path)
    end
  end
end
```

### 10.3 spec/features/events/show_event_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Show Event", type: :feature do
  let!(:event) do
    create(:event,
      title:       "Kill 'Em All",
      description: "Metallica's debut studio album.",
      day:         25,
      month:       7,
      year:        1983
    )
  end

  it "displays the event title" do
    visit event_path(event)
    expect(page).to have_content("Kill 'Em All")
  end

  it "displays the description" do
    visit event_path(event)
    expect(page).to have_content("Metallica's debut studio album.")
  end

  it "displays the formatted date" do
    visit event_path(event)
    expect(page).to have_content("25 Jul 1983")
  end

  it "is accessible via a friendly URL" do
    visit "/events/kill-em-all"
    expect(page).to have_content("Kill 'Em All")
  end

  it "has links to edit and go back to the list" do
    visit event_path(event)
    expect(page).to have_link("Edit")
    expect(page).to have_link("Back to Events")
  end

  it "returns 404 for a non-existent event" do
    visit event_path(id: "does-not-exist")
    expect(page).to have_http_status(:not_found)
  end

  context "when the event has no year" do
    let!(:undated_event) do
      create(:event, title: "Annual Concert", day: 15, month: 8, year: nil)
    end

    it "displays just the day and month" do
      visit event_path(undated_event)
      expect(page).to have_content("15 Aug")
      expect(page).not_to have_content("15 Aug nil")
    end
  end
end
```

### 10.4 spec/features/events/edit_event_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Edit Event", type: :feature do
  let!(:event) do
    create(:event, title: "Kill 'Em All", day: 25, month: 7, year: 1983)
  end

  it "updates the event's details" do
    visit edit_event_path(event)

    fill_in "Description", with: "Updated description."
    fill_in "Year",        with: "1984"
    click_button "Save Event"

    expect(page).to have_current_path(event_path(event))
    expect(page).to have_content("Updated description.")
    expect(page).to have_content("Event was successfully updated.")
  end

  it "shows a validation error when title is removed" do
    visit edit_event_path(event)

    fill_in "Title", with: ""
    click_button "Save Event"

    expect(page).to have_content("Title can't be blank")
  end

  context "when updating would create a duplicate title" do
    before { create(:event, title: "Ride the Lightning", day: 27, month: 7, year: 1984) }

    it "shows a uniqueness error" do
      visit edit_event_path(event)

      fill_in "Title", with: "Ride the Lightning"
      click_button "Save Event"

      expect(page).to have_content("Title has already been taken")
    end
  end
end
```

### 10.5 spec/features/events/delete_event_spec.rb

```ruby
require "rails_helper"

RSpec.describe "Delete Event", type: :feature do
  let!(:event) { create(:event, title: "Kill 'Em All", day: 25, month: 7, year: 1983) }

  it "deletes the event and redirects to the list" do
    visit event_path(event)
    click_button "Delete Event"

    expect(page).to have_current_path(events_path)
    expect(page).to have_content("Event was successfully deleted.")
    expect(page).not_to have_content("Kill 'Em All")
  end

  it "reduces the event count by 1" do
    expect {
      visit event_path(event)
      click_button "Delete Event"
    }.to change(Event, :count).by(-1)
  end
end
```

---

## Phase 11: Seeds — Metallica Album Releases

Let's populate the development database with all of Metallica's studio album releases. The `title` uniqueness validation means we use `find_or_create_by` to keep the seeds idempotent (safe to run more than once).

```ruby
# db/seeds.rb

# ── People ────────────────────────────────────────────────────────────────
puts "Seeding people..."

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

puts "Seeded #{Person.count} people."

# ── Events ────────────────────────────────────────────────────────────────
puts "Seeding events..."

metallica_albums = [
  { title: "Kill 'Em All",                   day: 25, month: 7,  year: 1983, description: "Metallica's debut studio album. Originally titled 'Metal Up Your Ass'." },
  { title: "Ride the Lightning",             day: 27, month: 7,  year: 1984, description: "Second studio album. A step forward in complexity and heaviness." },
  { title: "Master of Puppets",              day: 3,  month: 3,  year: 1986, description: "Widely considered one of the greatest heavy metal albums ever made." },
  { title: "...And Justice for All",         day: 5,  month: 9,  year: 1988, description: "Fourth studio album, notable for its extremely dry bass sound." },
  { title: "Metallica (The Black Album)",    day: 12, month: 8,  year: 1991, description: "The self-titled 'Black Album'. One of the best-selling albums of all time." },
  { title: "Load",                           day: 4,  month: 6,  year: 1996, description: "Sixth studio album, marking a shift toward hard rock and blues influences." },
  { title: "Reload",                         day: 18, month: 11, year: 1997, description: "Companion album to Load, featuring songs written during the same sessions." },
  { title: "St. Anger",                      day: 5,  month: 6,  year: 2003, description: "Eighth studio album, recorded during a turbulent period for the band." },
  { title: "Death Magnetic",                 day: 12, month: 9,  year: 2008, description: "Ninth studio album, a return to the thrash metal sound of their earlier work." },
  { title: "Hardwired... to Self-Destruct",  day: 18, month: 11, year: 2016, description: "Tenth studio album. A double album released after an eight-year hiatus." },
  { title: "72 Seasons",                     day: 14, month: 4,  year: 2023, description: "Eleventh studio album. The title refers to the first 18 years of one's life." }
]

metallica_albums.each do |attrs|
  Event.find_or_create_by!(title: attrs[:title]) do |e|
    e.description = attrs[:description]
    e.day         = attrs[:day]
    e.month       = attrs[:month]
    e.year        = attrs[:year]
  end
end

puts "Seeded #{Event.count} events."
puts "Done."
```

Run the seeds:

```bash
rails db:seed
```

---

## Phase 12: Run the Full Test Suite

```bash
# Full suite
bundle exec rspec

# Model specs only
bundle exec rspec spec/models/event_spec.rb

# Feature specs only
bundle exec rspec spec/features/events/

# Security scan
bundle exec brakeman -q

# Linting
bundle exec rubocop --autocorrect-all
```

Expected output:

```
...........................................................................
Finished in 2.62 seconds (files took 1.77 seconds to load)
75 examples, 0 failures
Coverage: 95.51%

== Brakeman Report ==
Security Warnings: 0

52 files inspected, no offenses detected
```

---

## Phase 13: Git Hooks & GitHub Actions

Before we commit and push, it's worth documenting the quality gates that protect every push to this repository. There are four of them: two local git hooks and two GitHub Actions workflows.

---

### 13.1 Local Git Hooks

Git hooks live in `.githooks/` (not the default `.git/hooks/`) so they can be committed to the repository and shared. To activate them, tell git where to find them — run this once after cloning:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/commit-msg .githooks/pre-push
```

#### .githooks/commit-msg

This hook fires every time you run `git commit`. It validates the commit message against a required format before the commit is recorded.

```bash
#!/bin/bash
COMMIT_MSG_FILE=$1
COMMIT_MSG=$(head -n 1 "$COMMIT_MSG_FILE")

# Allowed apps
APPS="Main|Event_Tracker|Blog_Posts|Recipes|Photo_Album"

# Allowed types
TYPES="feat|fix|refactor|test|chore|docs|style|perf|build|revert"

# Regex: <app>: <type>: <description (min 10 chars)>
REGEX="^(${APPS}):[[:space:]]+(${TYPES}):[[:space:]]+(.{10,})$"

if [[ ! $COMMIT_MSG =~ $REGEX ]]; then
  echo ""
  echo "❌ Invalid commit message format"
  echo ""
  echo "Expected:"
  echo "<app>: <type>: <description (min 10 chars)>"
  echo ""
  echo "Example:"
  echo "Event_Tracker:  feat:  Add Event model with TDD"
  echo ""
  echo "Allowed apps:   Main, Event_Tracker, Blog_Posts, Recipes, Photo_Album"
  echo "Allowed types:  feat, fix, refactor, test, chore, docs, style, perf, build, revert"
  echo ""
  exit 1
fi
exit 0
```

A valid commit message looks like:

```
Event_Tracker:  feat:  Add Event model with TDD — model, specs, factory, controller, views, seeds
```

An invalid message — like the placeholder we used earlier in this post — would be rejected immediately:

```
❌ Invalid commit message format
```

This forces every commit to be attributable to an app area and a change type before it ever touches the repository.

#### .githooks/pre-push

This hook fires on `git push`. It re-validates every commit that hasn't yet reached `origin/main`, catching any that slipped through (for example, commits made with `--no-verify`):

```bash
#!/bin/bash
echo "🔍 Validating commit messages before push..."

COMMITS=$(git log origin/main..HEAD --pretty=format:%s)

APPS="Main|Event_Tracker|Blog_Posts|Recipes|Photo_Album"
TYPES="feat|fix|refactor|test|chore|docs|style|perf|build|revert"
REGEX="^(${APPS}):[[:space:]]+(${TYPES}):[[:space:]]+(.{10,})$"

while read -r COMMIT; do
  if [[ ! $COMMIT =~ $REGEX ]]; then
    echo "❌ Invalid commit found:"
    echo "   $COMMIT"
    exit 1
  fi
done <<< "$COMMITS"

echo "✅ All commits valid"
```

The two hooks complement each other: `commit-msg` stops bad messages at the point of authoring, `pre-push` is the safety net that catches anything that bypassed it.

---

### 13.2 GitHub Actions

Two workflow files live in `.github/workflows/`. They run on every pull request and on every push to `main`.

#### .github/workflows/ci.yml

The main CI pipeline runs four jobs in parallel: security scanning, JavaScript auditing, linting, and the test suite.

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  scan_ruby:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Brakeman security scan
        run: bin/brakeman --no-pager
      - name: Bundler audit
        run: bin/bundler-audit

  scan_js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Importmap audit
        run: bin/importmap audit

  lint:
    runs-on: ubuntu-latest
    env:
      RUBOCOP_CACHE_ROOT: tmp/rubocop
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: RuboCop cache
        uses: actions/cache@v4
        env:
          DEPENDENCIES_HASH: ${{ hashFiles('.ruby-version', '**/.rubocop.yml', '**/.rubocop_todo.yml', 'Gemfile.lock') }}
        with:
          path: ${{ env.RUBOCOP_CACHE_ROOT }}
          key: rubocop-${{ runner.os }}-${{ env.DEPENDENCIES_HASH }}-${{ github.ref_name == github.event.repository.default_branch && github.run_id || 'default' }}
          restore-keys: rubocop-${{ runner.os }}-${{ env.DEPENDENCIES_HASH }}-
      - name: Lint
        run: bin/rubocop -f github

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=3
    steps:
      - run: sudo apt-get update && sudo apt-get install --no-install-recommends -y libpq-dev
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Run tests
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432
        run: bin/rails db:test:prepare test

  system-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=3
    steps:
      - run: sudo apt-get update && sudo apt-get install --no-install-recommends -y libpq-dev
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Run system tests
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432
        run: bin/rails db:test:prepare test:system
      - name: Upload screenshots from failed tests
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screenshots
          path: ${{ github.workspace }}/tmp/screenshots
          if-no-files-found: ignore
```

The `test` job runs `bin/rails db:test:prepare test` — the standard Minitest suite. The `system-test` job runs `test:system` separately and uploads screenshots on failure, which is invaluable for debugging Capybara failures in CI where you can't see the browser. Since we're using RSpec rather than Minitest, the `run:` lines need to be updated:

```yaml
# In the test job — replace the run line with:
run: bundle exec rspec spec/ --exclude-pattern "spec/features/**/*_spec.rb"

# In the system-test job — replace the run line with:
run: bundle exec rspec spec/features/
```

#### .github/workflows/commit-lint.yml

This workflow replicates the `pre-push` hook check in CI, catching any commits that were pushed with `--no-verify`:

```yaml
name: Commit Message Lint

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  lint-commits:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Validate commit messages
        run: |
          APPS="Main|Event_Tracker|Blog_Posts|Recipes|Photo_Album"
          TYPES="feat|fix|refactor|test|chore|docs|style|perf|build|revert"
          REGEX="^(${APPS}):[[:space:]]+(${TYPES}):[[:space:]]+(.{10,})$"

          COMMITS=$(git log origin/${{ github.base_ref }}..HEAD --pretty=format:%s)
          FAIL=0

          while read -r COMMIT; do
            echo "Checking: $COMMIT"
            if [[ ! $COMMIT =~ $REGEX ]]; then
              echo "❌ Invalid: $COMMIT"
              FAIL=1
            else
              echo "✅ OK"
            fi
          done <<< "$COMMITS"

          if [ $FAIL -ne 0 ]; then
            echo "❌ Commit message linting failed"
            exit 1
          fi
          echo "🎉 All commit messages are valid!"
```

`fetch-depth: 0` is required — without it the checkout is shallow and `git log origin/main..HEAD` can't see the full commit history, so it silently validates nothing.

---

### 13.3 The Full Quality Gate Picture

Every commit passes through four checkpoints:

| When | Gate | What it checks |
|---|---|---|
| `git commit` | `commit-msg` hook | Commit message format |
| `git push` | `pre-push` hook | All unpushed commit messages |
| PR opened / updated | `commit-lint.yml` | All PR commit messages (CI fallback) |
| PR opened / updated | `ci.yml` | Brakeman, bundler-audit, importmap audit, RuboCop, RSpec, system tests |

Nothing merges to `main` unless all four are green.

---

## Phase 14: Commit, Push & Open a Pull Request

Now that the quality gates are documented, here's the full flow from working code to merged PR.

```bash
# Make sure we're on the feature branch
git status

# Stage and commit — the commit-msg hook will validate the format
git add .
git commit -m "Event_Tracker:  feat:  Add Event model with TDD — model, specs, factory, controller, views, seeds"

# Merge main into the feature branch to pick up any changes and resolve conflicts here
git merge main

# Push — the pre-push hook validates all commit messages before the push goes through
git push origin feature/event-model
```

Then open a Pull Request on GitHub targeting `main`. The `ci.yml` and `commit-lint.yml` workflows will run automatically. Once both are green, merge the PR on GitHub — never merge the feature branch into `main` locally.

Once merged on GitHub, sync locally and clean up:

```bash
git checkout main
git pull origin main
git branch -d feature/event-model
```

---

## Lessons Learned in Post #2

**1. `friendly_id` with `:history` is almost always the right choice.** Without history, renaming a person or event breaks every old URL silently. With history, old slugs resolve to the new record via a redirect. The cost is a single extra table — well worth it.

**2. Virtual attributes don't get `_changed?` dirty-tracking methods.** `full_name` is computed from real columns, not stored itself, so Rails has no `full_name_changed?` method. The fix is to check the underlying real columns directly: `first_name_changed? || middle_name_changed? || last_name_changed?`. This is one of those bugs that only surfaces once you actually rename a record — write the spec for slug regeneration before you ship.

**3. Always add `should_generate_new_friendly_id?` or slugs won't update.** `friendly_id` generates the slug once on create and leaves it alone after that unless you tell it otherwise. Without overriding `should_generate_new_friendly_id?`, renaming an event leaves the old slug in place permanently. Because `title` is a real column, `title_changed?` works correctly here — contrast with `Person` where we had to check the underlying name columns individually.

**4. Reload the record after an update that changes the slug.** After a `click_button` that triggers an update, the in-memory object still holds the old slug. Calling `person_path(person)` then generates the old URL, causing a false mismatch even though the app behaved correctly. Fix: call `person.reload` before asserting on the path. This applies to any spec where a form submission can change `to_param`.

**5. `"nil"` and `nil` are not the same thing.** Passing `middle_name: "nil"` sets the field to the four-character string "nil", which ends up in the slug. Always use the bare Ruby keyword `nil` for null values in factories and test data.

**6. `rails runner` chokes on shell metacharacters.** The `&` in `Person.find_each(&:save)` is interpreted by the shell before Ruby ever sees it when wrapped in double quotes. Use the Rails console directly, or write the one-liner to a temp file and pass the file path to `rails runner`.

**7. Optional year required a custom `display_date` method.** Rails' `Date` formatting helpers need a full date object. Since year is optional, we can't construct one, so `display_date` builds the string manually from parts. Simple and explicit.

**8. `NULLS LAST` matters in reverse chronological ordering.** Undated events (`year: nil`) would sort before everything else with a plain `ORDER BY year DESC`. `NULLS LAST` pushes them to the bottom, which is almost always the right UX.

**9. `shoulda-matchers` and `numericality: { in: 1..31 }` don't get along.** Rails accepts the `in:` shorthand and produces the error message `"must be in 1..31"`, but the `validate_numericality_of` matcher expects `"must be greater than or equal to 1"`. Use explicit `greater_than_or_equal_to:` and `less_than_or_equal_to:` options — they mean the same thing and both tools agree on the error messages.

**10. Never ship generator-default factories.** Rails scaffolds factories with literal placeholder values like `"MyString"`, `1`, and `"MyText"`. These will silently break any spec that asserts on a slug, a formatted value, or uniqueness. Always replace them immediately with `Faker` values, sequences, and sensible defaults before writing a single spec.

**11. Delete generator stubs immediately.** The controller generator creates empty request specs and view specs as stubs. Left in place they show up as pending noise in the suite output. Delete them the moment the generator finishes — the feature specs cover everything those stubs would have tested.

**12. Use `page.text.index` for ordering assertions, not CSS selectors.** A selector like `"h2, td.event-title, .event-title"` is tightly coupled to the current markup. `page.text.index("Title A") < page.text.index("Title B")` asserts purely on rendered text order and survives any HTML restructuring.

**13. Git hooks must be opted into after cloning.** Hooks in `.githooks/` aren't activated automatically — each developer needs to run `git config core.hooksPath .githooks` once. Document this in the project README so it doesn't get missed.

**14. `fetch-depth: 0` is required for commit history in GitHub Actions.** The default checkout action does a shallow clone. Without `fetch-depth: 0`, `git log origin/main..HEAD` sees no commits and silently validates nothing — the workflow passes and catches nothing.

**15. Merge `main` into the feature branch before opening a PR, not after.** Conflicts belong on the feature branch, not on `main`. Resolve them locally, push the resolved branch, then let GitHub merge via the PR.

---

## What's Next

In **Post #3** we'll introduce the `EventType` model (Birthday, Education, Work, Sport, Wedding, Music) and wire up the `belongs_to :event_type` association on `Event`. We'll also link events to people with `belongs_to :person`, completing the core relationships at the heart of the Event Tracker.

Stay tuned — and as always, if you spot anything I could do better, feel free to reach out.

---

*Bergstrom | bergstromdomain.com | Building in public, one commit at a time.*
