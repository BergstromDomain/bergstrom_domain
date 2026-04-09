# Post #3 — The EventType Model

Every event needs a category. A birthday is different from a concert. A graduation is different from a wedding. Before we can properly classify anything in this app, we need an `EventType` model — a simple lookup table with a name, a description, and an icon. That's what this post covers.

We pick an icon library, wire up a visual icon picker for the form, and seed six event types. Associations — `Event → EventType` and `Event → Person` — are covered in Post #4 alongside a proper deep dive into ActiveRecord association types.

Branch: `feature/event-type-model`

---

## Phase 1 — Branch & Route

```bash
git checkout -b feature/event-type-model
```

Add the route now so the generator doesn't leave anything orphaned:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :people
  resources :events
  resources :event_types
  root "people#index"
end
```

---

## Phase 2 — Icons: Choosing a Library

We need free, easy-to-embed icons. The requirements:

- Available as a gem or via a CDN import in the asset pipeline
- Large set of icons (hundreds, not dozens)
- Usable inline (not just as img tags) so we can style them with CSS
- License permitting commercial use

**Recommendation: Lucide Icons via the `lucide-rails` gem.**

Lucide is a community fork of Feather Icons with 1,400+ SVG icons, MIT licensed, and actively maintained. The `lucide-rails` gem makes every icon available as a Rails view helper: `lucide_icon("calendar")` renders an inline SVG. Icons accept `class:` and `size:` options, so they style easily with CSS or Tailwind.

```ruby
# Gemfile
gem "lucide-rails"
```

```bash
bundle install
```

No asset pipeline config needed — the gem registers itself as a helper. That's it.

Later, when we add buttons sitewide, the same helper works everywhere: `lucide_icon("trash-2", class: "icon")`.

The icon name for each `EventType` will be stored as a plain string (e.g. `"cake"`, `"briefcase"`, `"music"`) — whatever Lucide calls it. The view helper turns that string into an SVG at render time.

---

## Phase 3 — Generate the Model (Red)

### 3.1 Generate

```bash
rails generate model EventType name:string description:text icon:string slug:string
```

Edit the migration before running it. Add `null: false` constraints and indexes manually — the generator doesn't accept that syntax inline:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_event_types.rb
class CreateEventTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :event_types do |t|
      t.string   :name,        null: false
      t.text     :description, null: false
      t.string   :icon,        null: false
      t.string   :slug

      t.timestamps
    end

    add_index :event_types, :name, unique: true
    add_index :event_types, :icon, unique: true
    add_index :event_types, :slug, unique: true
  end
end
```

```bash
rails db:migrate
```

### 3.2 Write the spec first (Red)

Delete the generator stubs:

```bash
rm -rf spec/views/event_types/
```

Note: the controller generator creates `spec/views/` stubs but not `spec/requests/` — only the model and scaffold generators do that. Delete only what exists.

Create the model spec:

```ruby
# spec/models/event_type_spec.rb
require "rails_helper"

RSpec.describe EventType, type: :model do
  describe "database columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:icon).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
  end

  describe "validations" do
    subject { build(:event_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:icon) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:icon) }

    context "when name differs only in case" do
      before { create(:event_type, name: "Music") }

      it "is invalid" do
        et = build(:event_type, name: "music")
        expect(et).not_to be_valid
        expect(et.errors[:name]).to include("has already been taken")
      end
    end

    context "when icon is already taken" do
      before { create(:event_type, icon: "music") }

      it "is invalid" do
        et = build(:event_type, icon: "music")
        expect(et).not_to be_valid
        expect(et.errors[:icon]).to include("has already been taken")
      end
    end
  end

  describe "FriendlyId" do
    it "generates a slug from name on create" do
      et = create(:event_type, name: "Work Experience")
      expect(et.slug).to eq("work-experience")
    end

    it "updates slug when name changes" do
      et = create(:event_type, name: "Birthday")
      et.update!(name: "Anniversary")
      et.reload
      expect(et.slug).to eq("anniversary")
    end

    it "finds record by slug" do
      et = create(:event_type, name: "Sport")
      expect(EventType.friendly.find("sport")).to eq(et)
    end
  end
end
```

Run the spec — everything fails. Good, we're Red.

```bash
bundle exec rspec spec/models/event_type_spec.rb
```

---

## Phase 4 — Implement the Model (Green)

```ruby
# app/models/event_type.rb
class EventType < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]

  # ── Validations ──────────────────────────────────────────────────────────
  validates :name,        presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true
  validates :icon,        presence: true, uniqueness: true

  # ── FriendlyId ───────────────────────────────────────────────────────────
  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
```

Run the spec again:

```bash
bundle exec rspec spec/models/event_type_spec.rb
```

All green.

---

## Phase 5 — Factory

```ruby
# spec/factories/event_types.rb
FactoryBot.define do
  factory :event_type do
    sequence(:name) { |n| "EventType #{n}" }
    description     { Faker::Lorem.paragraph }
    sequence(:icon) { |n| "icon-#{n}" }
  end
end
```

No random data for anything that participates in uniqueness constraints. The `sequence` blocks guarantee no collisions between tests.

---

## Phase 6 — Controller & Views

### 6.1 Generate the controller

```bash
rails generate controller EventTypes index show new edit
```

Delete the generated stubs:

```bash
rm -rf spec/views/event_types/
```

### 6.2 Controller

```ruby
# app/controllers/event_types_controller.rb
class EventTypesController < ApplicationController
  before_action :set_event_type, only: %i[show edit update destroy]

  def index
    @event_types = EventType.order(:name)
  end

  def show; end

  def new
    @event_type = EventType.new
  end

  def create
    @event_type = EventType.new(event_type_params)
    if @event_type.save
      redirect_to @event_type, notice: "Event type created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @event_type.update(event_type_params)
      redirect_to @event_type, notice: "Event type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event_type.destroy
    redirect_to event_types_path, notice: "Event type deleted."
  end

  private

  def set_event_type
    @event_type = EventType.friendly.find(params[:id])
  end

  def event_type_params
    params.require(:event_type).permit(:name, :description, :icon)
  end
end
```

### 6.3 Icon helper

We need a list of Lucide icon names for the picker. The icons are compiled into a gzipped binary inside the gem — there are no individual SVG files to glob. To find valid names, extract them from the binary:

```bash
bundle exec ruby -e "
require 'lucide-rails'
require 'zlib'
path = LucideRails::GEM_ROOT.join('icons/stripped.bin.gz')
data = Zlib::GzipReader.open(path) { |gz| gz.read }
puts data.scan(/[\w-]+/).uniq.select { |n| n.match?(/^[a-z][\w-]+$/) }.sort
" > /tmp/lucide_icons.txt
```

Then grep to confirm the names you want actually exist in your installed version:

```bash
grep -E "^(cake|briefcase|graduation-cap|dumbbell|heart|music|...)$" /tmp/lucide_icons.txt
```

Only include names confirmed present — Lucide's icon set changes between releases and the gem version in your `Gemfile.lock` determines what's available. Any unrecognised name raises `Unknown icon` at render time.

The verified list for `lucide-rails` 0.7.4:

```ruby
# app/helpers/event_types_helper.rb
module EventTypesHelper
  LUCIDE_ICON_OPTIONS = %w[
    activity award baby bookmark briefcase cake camera car
    coffee crown dumbbell flag flame gift graduation-cap heart
    home laptop leaf map-pin medal mic music pencil plane
    shield shopping-bag smile star sun ticket trophy
    umbrella users utensils video wallet zap
  ].freeze
end
```

### 6.4 Views

`app/views/event_types/_form.html.erb`
```erb
<%= form_with(model: event_type) do |f| %>
  <% if event_type.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(event_type.errors.count, "error") %> prohibited this event type from being saved:</h2>
      <ul>
        <% event_type.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name %>
    <%= f.text_field :name %>
  </div>

  <div>
    <%= f.label :description %>
    <%= f.text_area :description, rows: 4 %>
  </div>

  <div>
    <%= f.label :icon, "Icon" %>
    <p>
      <%= link_to "Browse all Lucide icons", "https://lucide.dev/icons/",
            target: "_blank", rel: "noopener noreferrer" %>
    </p>

    <%# Hidden field holds the selected value %>
    <%= f.hidden_field :icon, id: "icon_value" %>

    <%# Visual grid of icons to pick from %>
    <div id="icon-picker">
      <% EventTypesHelper::LUCIDE_ICON_OPTIONS.each do |icon_name| %>
        <button type="button"
                class="icon-option <%= 'selected' if event_type.icon == icon_name %>"
                data-icon="<%= icon_name %>"
                title="<%= icon_name %>">
          <%= lucide_icon(icon_name, size: 24) %>
          <span><%= icon_name %></span>
        </button>
      <% end %>
    </div>

    <p id="selected-icon-label">
      Selected: <strong id="selected-icon-name"><%= event_type.icon.presence || "none" %></strong>
    </p>
  </div>

  <div>
    <%= f.submit %>
  </div>
<% end %>

<script>
  document.addEventListener("DOMContentLoaded", function () {
    const hiddenField = document.getElementById("icon_value");
    const nameLabel   = document.getElementById("selected-icon-name");
    const buttons     = document.querySelectorAll(".icon-option");

    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        buttons.forEach(function (b) { b.classList.remove("selected"); });
        btn.classList.add("selected");
        hiddenField.value = btn.dataset.icon;
        nameLabel.textContent = btn.dataset.icon;
      });
    });
  });
</script>
```

The picker is a flat grid of buttons. Each renders the Lucide SVG plus the icon name. Clicking one sets the hidden field and highlights the selection. No JavaScript framework required. The "Browse all Lucide icons" link opens in a new tab — `rel: "noopener noreferrer"` is the standard security attribute that always accompanies `target: "_blank"` links.

Add minimal CSS:

```css
/* Icon picker */
#icon-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #ccc;
  padding: 12px;
  border-radius: 4px;
}

.icon-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px;
  border: 2px solid transparent;
  border-radius: 6px;
  background: none;
  cursor: pointer;
  font-size: 11px;
  color: #555;
  width: 72px;
}

.icon-option:hover {
  border-color: #aaa;
  background: #f5f5f5;
}

.icon-option.selected {
  border-color: #2563eb;
  background: #eff6ff;
  color: #1d4ed8;
}

.icon-option svg {
  display: block;
}
```

`app/views/event_types/index.html.erb`
```erb
<h1>Event Types</h1>

<%= link_to "New Event Type", new_event_type_path %>

<% @event_types.each do |et| %>
  <div>
    <%= lucide_icon(et.icon, size: 20) %>
    <%= link_to et.name, event_type_path(et) %>
  </div>
<% end %>
```

`app/views/event_types/show.html.erb`
```erb
<h1>
  <%= lucide_icon(@event_type.icon, size: 32) %>
  <%= @event_type.name %>
</h1>

<p><%= @event_type.description %></p>

<p>Icon: <code><%= @event_type.icon %></code></p>

<%= link_to "Edit", edit_event_type_path(@event_type) %>

<%= button_to "Delete Event Type", event_type_path(@event_type),
      method: :delete,
      data: { turbo_confirm: "Are you sure?" } %>
```

`app/views/event_types/new.html.erb`
```erb
<h1>New Event Type</h1>

<%= render "form", event_type: @event_type %>

<%= link_to "Back", event_types_path %>
```

`app/views/event_types/edit.html.erb`
```erb
<h1>Edit Event Type</h1>

<%= render "form", event_type: @event_type %>

<%= link_to "Back", event_type_path(@event_type) %>
```

---

## Phase 7 — Feature Specs (Red → Green)

One file per CRUD action. Any spec that interacts with the icon picker needs `js: true` — Capybara's default driver runs without JavaScript, so the picker's DOM manipulation won't fire without it.

### 7.1 List

```ruby
# spec/features/event_types/list_event_types_spec.rb
require "rails_helper"

RSpec.describe "List event types", type: :feature do
  it "displays all event types ordered by name" do
    create(:event_type, name: "Work",     icon: "briefcase",  description: "Work events")
    create(:event_type, name: "Birthday", icon: "cake",       description: "Birthday events")
    create(:event_type, name: "Sport",    icon: "dumbbell",   description: "Sport events")

    visit event_types_path

    expect(page).to have_content("Birthday")
    expect(page).to have_content("Sport")
    expect(page).to have_content("Work")

    positions = ["Birthday", "Sport", "Work"].map { |n| page.text.index(n) }
    expect(positions).to eq(positions.sort)
  end
end
```

### 7.2 Show

```ruby
# spec/features/event_types/show_event_type_spec.rb
require "rails_helper"

RSpec.describe "Show event type", type: :feature do
  it "displays the event type details" do
    et = create(:event_type, name: "Music", icon: "music", description: "Musical events and performances")

    visit event_type_path(et)

    expect(page).to have_content("Music")
    expect(page).to have_content("Musical events and performances")
    expect(page).to have_content("music")
  end
end
```

### 7.3 Create

```ruby
# spec/features/event_types/create_event_type_spec.rb
require "rails_helper"

RSpec.describe "Create event type", type: :feature do
  it "creates an event type via the form", js: true do
    visit new_event_type_path

    fill_in "Name",        with: "Education"
    fill_in "Description", with: "School, university, and learning milestones"

    find(".icon-option[data-icon='graduation-cap']").click

    click_button "Create Event type"

    expect(page).to have_content("Education")
    expect(page).to have_content("Event type created.")
  end

  it "shows errors when name is missing" do
    visit new_event_type_path

    fill_in "Description", with: "Something"
    click_button "Create Event type"

    expect(page).to have_content("can't be blank")
  end

  it "shows errors when name is a duplicate (case-insensitive)" do
    create(:event_type, name: "Music", icon: "music", description: "Musical events")

    visit new_event_type_path
    fill_in "Name",        with: "music"
    fill_in "Description", with: "Another music type"
    click_button "Create Event type"

    expect(page).to have_content("has already been taken")
  end
end
```

### 7.4 Edit

```ruby
# spec/features/event_types/edit_event_type_spec.rb
require "rails_helper"

RSpec.describe "Edit event type", type: :feature do
  it "updates name and regenerates slug" do
    et = create(:event_type, name: "Fitness", icon: "dumbbell", description: "Fitness events")

    visit edit_event_type_path(et)
    fill_in "Name", with: "Sport"
    click_button "Update Event type"

    et.reload
    expect(page).to have_current_path(event_type_path(et))
    expect(page).to have_content("Event type updated.")
    expect(page).to have_content("Sport")
    expect(et.slug).to eq("sport")
  end

  it "shows errors on invalid update" do
    create(:event_type, name: "Work",  icon: "briefcase", description: "Work events")
    et = create(:event_type, name: "Sport", icon: "dumbbell",  description: "Sport events")

    visit edit_event_type_path(et)
    fill_in "Name", with: "Work"
    click_button "Update Event type"

    expect(page).to have_content("has already been taken")
  end
end
```

### 7.5 Delete

```ruby
# spec/features/event_types/delete_event_type_spec.rb
require "rails_helper"

RSpec.describe "Delete event type", type: :feature do
  it "deletes an event type and redirects to index" do
    et = create(:event_type, name: "Wedding", icon: "heart", description: "Wedding events")

    visit event_type_path(et)
    click_button "Delete Event Type"

    expect(page).to have_current_path(event_types_path)
    expect(page).to have_content("Event type deleted.")
    expect(page).not_to have_content("Wedding")
  end
end
```

Run all feature specs:

```bash
bundle exec rspec spec/features/event_types/
```

All eight pass. Green.

---

## Phase 8 — Seeds

```ruby
# db/seeds.rb

# ── EventTypes ───────────────────────────────────────────────────────────
event_types_data = [
  {
    name:        "Birthday",
    description: "Birth anniversaries and birthday celebrations.",
    icon:        "cake"
  },
  {
    name:        "Education",
    description: "School, university, graduation, and other learning milestones.",
    icon:        "graduation-cap"
  },
  {
    name:        "Work",
    description: "Career milestones, job changes, promotions, and professional achievements.",
    icon:        "briefcase"
  },
  {
    name:        "Sport",
    description: "Sporting achievements, competitions, and fitness milestones.",
    icon:        "dumbbell"
  },
  {
    name:        "Wedding",
    description: "Marriages, civil ceremonies, and anniversary celebrations.",
    icon:        "heart"
  },
  {
    name:        "Music",
    description: "Album releases, concerts, tours, and musical milestones.",
    icon:        "music"
  }
]

event_types_data.each do |attrs|
  EventType.find_or_create_by!(name: attrs[:name]) do |et|
    et.description = attrs[:description]
    et.icon        = attrs[:icon]
  end
end

puts "Seeded #{EventType.count} event types."

# ── People ───────────────────────────────────────────────────────────────
people = [
  { first_name: "James",  middle_name: "Alan",   last_name: "Hetfield",
    description: "Vocalist and rhythm guitarist. Co-founder of Metallica." },
  { first_name: "Lars",   middle_name: nil,       last_name: "Ulrich",
    description: "Drummer and co-founder of Metallica." },
  { first_name: "Kirk",   middle_name: "Lee",     last_name: "Hammett",
    description: "Lead guitarist of Metallica since 1983." },
  { first_name: "Robert", middle_name: "George",  last_name: "Trujillo",
    description: "Bassist of Metallica since 2003." }
]

people.each do |attrs|
  Person.find_or_create_by!(
    first_name:  attrs[:first_name],
    middle_name: attrs[:middle_name],
    last_name:   attrs[:last_name]
  ) do |p|
    p.description = attrs[:description]
  end
end

puts "Seeded #{Person.count} people."

# ── Events (Metallica albums) ─────────────────────────────────────────────
metallica_albums = [
  { title: "Kill 'Em All",                  day: 25, month: 7,  year: 1983 },
  { title: "Ride the Lightning",            day: 27, month: 7,  year: 1984 },
  { title: "Master of Puppets",             day: 3,  month: 3,  year: 1986 },
  { title: "...And Justice for All",        day: 25, month: 8,  year: 1988 },
  { title: "Metallica (Black Album)",       day: 12, month: 8,  year: 1991 },
  { title: "Load",                          day: 4,  month: 6,  year: 1996 },
  { title: "Reload",                        day: 18, month: 11, year: 1997 },
  { title: "St. Anger",                     day: 5,  month: 6,  year: 2003 },
  { title: "Death Magnetic",                day: 12, month: 9,  year: 2008 },
  { title: "Hardwired... to Self-Destruct", day: 18, month: 11, year: 2016 },
  { title: "72 Seasons",                    day: 14, month: 4,  year: 2023 }
]

metallica_albums.each do |attrs|
  Event.find_or_create_by!(title: attrs[:title]) do |e|
    e.day         = attrs[:day]
    e.month       = attrs[:month]
    e.year        = attrs[:year]
    e.description = "Metallica studio album released on #{attrs[:day]}/#{attrs[:month]}/#{attrs[:year]}."
  end
end

puts "Seeded #{Event.count} events."
```

```bash
rails db:seed
```

Output:

```
Seeded 6 event types.
Seeded 4 people.
Seeded 11 events.
```

---

## Phase 9 — Full Test Suite

```bash
bundle exec rspec
```

Everything passes. Check coverage:

```bash
open coverage/index.html
```

Coverage above 90%. Run the linter and security tools:

```bash
bundle exec rubocop
bundle exec brakeman -q
bundle exec bundler-audit check --update
```

No offences, no warnings.

---

## Phase 10 — Commit & Push

```bash
git add -A
git commit -m "Event_Tracker:  feat:  Add EventType model with icon picker and seed data"

git merge main
git push origin feature/event-type-model
```

Open the PR on GitHub. CI runs `ci.yml` (RSpec + Brakeman + bundler-audit) and `commit-lint.yml`. Both pass. Merge on GitHub.

```bash
git checkout main
git pull
git branch -d feature/event-type-model
```

---

## Lessons Learned

**The controller generator does not create `spec/requests/` stubs.** Only the model and scaffold generators do. After `rails generate controller`, only delete `spec/views/<resource>/` — there is no request spec to remove.

**Verify icon names against the installed gem version.** Lucide's icon set changes between releases. The gem compiles icons into a gzipped binary (`icons/stripped.bin.gz`) — there are no individual SVG files to glob. Extract names from the binary and grep to confirm before hardcoding them in the helper. Any unrecognised name raises `Unknown icon` at render time.

**`js: true` is required for any Capybara test that relies on JavaScript.** The default Rack test driver runs without a browser. Any test that clicks a JS-powered element — like the icon picker — needs `js: true` to run under Selenium.

**Drop `webdrivers`.** Chrome 115+ moved ChromeDriver to a new download endpoint that the `webdrivers` gem doesn't support. `selenium-webdriver` 4.11+ ships `selenium-manager` which handles driver management automatically. Never add `webdrivers` to new projects.

**Create `spec/support/` manually.** Rails generators don't create it. Add the directory, put `capybara.rb` in it, and wire it up in `rails_helper.rb` with `Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }`.

**`lucide_icon` renders inline SVG synchronously.** No JavaScript required at render time — icons work even with JS disabled. This matters for accessibility and for non-JS Capybara tests that render views containing icons.

**Icon picker state lives in a hidden field.** The picker grid is pure decoration. The form submits whatever value is in the hidden field. This keeps the form submission clean and Rails-conventional with no custom serialisation.

**`find_or_create_by!` with a block is idempotent.** The block only runs on create. Re-running `rails db:seed` is safe — existing records are found without modification.

**Always add `rel: "noopener noreferrer"` to `target: "_blank"` links.** Without it, the opened page can access the opener via `window.opener`. It's a one-liner and should be automatic.

---

## What's Next

Post #4 is a deep dive into ActiveRecord associations — one-to-one, one-to-many, and many-to-many — with the theory covered properly before any code is written. Then we wire up `Event → Person` and `Event → EventType`, both of which have been stubbed as comments in the `Event` model since Post #2. After Post #4 the core of the app will be fully connected.

---

*Bergstrom | bergstromdomain.com | Building in public, one commit at a time.*
