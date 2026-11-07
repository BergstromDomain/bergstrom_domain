# spec/features/blog_posts/guide_images_spec.rb
require "rails_helper"

# Takes the Chronicle User Guide screenshots in docs/user-guide/chronicle/
# images, in the story world (spec/support/guide_story_world.rb), so the app
# pages show the same Newton posts as the story. Skipped unless
# GUIDE_SCREENSHOTS=1 (see spec/support/guide_images.rb):
#
#   GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/blog_posts/guide_images_spec.rb
RSpec.describe "Chronicle Guide Images", type: :feature, js: true, guide_image: true do
  include ActiveSupport::Testing::TimeHelpers

  MARKDOWN_SAMPLE = <<~MARKDOWN.freeze
    ## The Prism Experiment

    Newton passed **sunlight** through a prism and saw *seven* colours.

    - Red, orange and yellow
    - Green and blue
    - Indigo and violet

    Read more on [Wikipedia](https://en.wikipedia.org/wiki/Isaac_Newton).
  MARKDOWN

  # Before the world is built (let! is a before hook too), so its dates are fixed.
  before { travel_to GuideStoryWorld::STORY_TIME }
  after  { travel_back }

  let!(:world) { build_story_world }

  before do
    sign_in_as(world.charlie)
    expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
  end

  it "Captures browsing and filtering" do
    create(:blog_category, name: "Technology", icon: "cpu", description: "Computers and code.")
    create(:blog_category, name: "Travel", icon: "plane", description: "Places and journeys.")
    visit blog_posts_path
    capture_guide_image("browse-tree", as: "chronicle/browse_categories")

    visit blog_posts_path(category_id: BlogCategory.find_by!(name: "Science").id, subject: "Physics")
    capture_guide_image(%w[browse-tree browse-preview], as: "chronicle/browse_subject")

    visit filter_blog_posts_path
    capture_guide_image(%w[basic-panel filter-results-table], as: "chronicle/filter_basic")

    visit filter_blog_posts_path(mode: "sql", query: 'topic = "Isaac Newton" AND comments > 0')
    expect(page).to have_css("[data-testid='filter-post-row']", count: 1, wait: 8)
    capture_guide_image(%w[sql-panel filter-results-table], as: "chronicle/filter_sql")
  end

  it "Captures the Raw and Formatted editors" do
    visit new_blog_post_path
    find("[data-testid='raw-tab']").click
    find("[data-testid='body-field']").set(MARKDOWN_SAMPLE)
    page.execute_script("const raw = document.querySelector('[data-testid=\"body-field\"]'); " \
                        "raw.style.height = raw.scrollHeight + 'px'; raw.scrollTop = 0")
    capture_guide_image("new-panel-body", as: "chronicle/markdown_raw")

    find("[data-testid='formatted-tab']").click
    expect(page).to have_css("[data-testid='quill-editor'] li", count: 3, wait: 8)
    capture_guide_image("new-panel-body", as: "chronicle/markdown_formatted")
  end

  it "Captures the import and download pages" do
    visit new_blog_import_path
    capture_guide_image("import-panel", as: "chronicle/import")

    visit blog_exports_path
    capture_guide_image(%w[export-panel download-action-panel], as: "chronicle/download")
  end
end
