# spec/features/events/guide_images_spec.rb
require "rails_helper"

# Takes the Occasions User Guide screenshots in docs/user-guide/occasions/
# images, in the story world (spec/support/guide_story_world.rb), so the app
# pages show the same friends and events as the story. Charlie owns them all,
# so every Visibility appears. Skipped unless GUIDE_SCREENSHOTS=1 (see
# spec/support/guide_images.rb):
#
#   GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/events/guide_images_spec.rb
RSpec.describe "Occasions Guide Images", type: :feature, js: true, guide_image: true do
  include ActiveSupport::Testing::TimeHelpers

  # Before the world is built (let! is a before hook too), so its dates are fixed.
  before { travel_to GuideStoryWorld::STORY_TIME }
  after  { travel_back }

  let!(:world) { build_story_world }

  before do
    platform = create(:social_media_platform, name: "Instagram", url: "https://www.instagram.com/",
      description: "Photos and short videos.")
    create(:person_social_media_account, person: world.people[:erik], social_media_platform: platform,
      username: "erik_climbs")

    sign_in_as(world.charlie)
    expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
  end

  it "Captures the event views and an event's page" do
    visit events_by_week_path
    capture_guide_image(%w[week-nav event-list], as: "occasions/events_by_week")

    visit events_by_month_path(month: 11)
    capture_guide_image(%w[month-nav event-list], as: "occasions/events_by_month")

    visit events_path
    capture_guide_image(%w[classification-nav events-table], as: "occasions/all_events")

    visit event_path(world.events[:wedding])
    capture_guide_image(%w[show-panel-main show-panel-actions], as: "occasions/event_page")
  end

  it "Captures People and a person's page" do
    visit people_path
    capture_guide_image(%w[az-nav people-table], as: "occasions/people")

    visit person_path(world.people[:erik])
    capture_guide_image(%w[show-panel-main show-panel-social-media], as: "occasions/person_page")
  end

  it "Captures Filter People and Events" do
    visit filter_people_events_path
    capture_guide_image(%w[basic-panel filter-results-table], as: "occasions/filter_basic")

    visit filter_people_events_path(mode: "sql", query: 'last_name = "Lind" AND event_type = "Wedding"')
    expect(page).to have_css("[data-testid='filter-row']", count: 2, wait: 8)
    capture_guide_image(%w[sql-panel filter-results-table], as: "occasions/filter_sql")
  end

  it "Captures the Create Event form, the import and the download" do
    visit new_event_path
    capture_guide_image("event-form", as: "occasions/event_form")

    visit new_people_events_import_path
    capture_guide_image("import-panel", as: "occasions/import")

    visit people_events_exports_path
    capture_guide_image(%w[export-panel download-action-panel], as: "occasions/download")
  end
end
