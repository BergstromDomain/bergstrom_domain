# spec/features/blog_posts/filter_blog_posts_spec.rb

require "rails_helper"

RSpec.describe "Filter blog posts", type: :feature do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    let!(:food)       { create(:blog_category, name: "Food") }
    let!(:technology) { create(:blog_category, name: "Technology") }
    let!(:food_post) do
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: food, title: "Apple Pie")
    end
    let!(:tech_post) do
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: technology,
        subject: "Software Development", topic: "Ruby On Rails", title: "Zebra Rails Tips")
    end

    it "Narrows results using a single Basic dropdown filter" do
      visit filter_blog_posts_path
      select "Technology", from: "category_id"
      click_button "Apply Filters"

      expect(page).to have_selector("[data-testid='filter-post-row']", count: 1)
      expect(page).to have_link("Zebra Rails Tips")
      expect(page).not_to have_link("Apple Pie")
    end

    it "Narrows results using several Basic filters combined (AND)" do
      visit filter_blog_posts_path(category_id: technology.slug, topic: "Ruby On Rails")

      expect(page).to have_selector("[data-testid='filter-post-row']", count: 1)
      expect(page).to have_link("Zebra Rails Tips")
    end

    it "Filters using a SQL-mode query with AND, OR, and parentheses" do
      visit filter_blog_posts_path(mode: "sql",
        query: 'category = "Technology" AND (topic = "Ruby On Rails" OR comments > 5)')

      expect(page).to have_selector("[data-testid='filter-post-row']", count: 1)
      expect(page).to have_link("Zebra Rails Tips")
    end

    it "Sorts results by a column and reverses direction on a second click, preserving the filter" do
      visit filter_blog_posts_path # "All Categories" default — both posts are visible

      click_link "Blog Title"
      titles = all("[data-testid='filter-post-title']").map(&:text)
      expect(titles).to eq([ "Apple Pie", "Zebra Rails Tips" ])

      click_link "Blog Title"
      titles = all("[data-testid='filter-post-title']").map(&:text)
      expect(titles).to eq([ "Zebra Rails Tips", "Apple Pie" ])
    end

    it "Narrows results using the Published dropdown" do
      sign_in_as(owner)
      create(:blog_post, user: owner, title: "My Draft") # no :published trait

      visit filter_blog_posts_path
      select "Published Only", from: "published"
      click_button "Apply Filters"

      expect(page).to have_content("Apple Pie")
      expect(page).not_to have_content("My Draft")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows a friendly error and no results for a malformed SQL query" do
      visit filter_blog_posts_path(mode: "sql", query: "category = ")

      expect(page).to have_selector("[data-testid='filter-error']")
      expect(page).not_to have_selector("[data-testid='filter-post-row']")
    end

    it "Never shows a restricted post to a guest, even with a permissive SQL filter" do
      category = create(:blog_category, name: "Secrets")
      create(:blog_post, :restricted, :published, user: owner, blog_category: category, title: "Hidden Post")

      visit filter_blog_posts_path(mode: "sql", query: "comments >= 0")

      expect(page).not_to have_content("Hidden Post")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets 'Adam Admin' filter drafts and restricted posts into view" do
      category = create(:blog_category, name: "Admin Only")
      create(:blog_post, :restricted, user: owner, blog_category: category, title: "Unpublished Draft")

      sign_in_as(create(:user, :admin))
      visit filter_blog_posts_path(category_id: category.slug)

      expect(page).to have_content("Unpublished Draft")
    end

    it "Toggles between Basic and SQL panels via the tab without a page reload", js: true do
      visit filter_blog_posts_path

      expect(page).to have_selector("[data-testid='basic-panel']", visible: true)
      expect(page).to have_selector("[data-testid='sql-panel']", visible: :hidden)

      find("[data-testid='sql-tab']").click

      expect(page).to have_selector("[data-testid='sql-panel']", visible: true)
      expect(page).to have_selector("[data-testid='basic-panel']", visible: :hidden)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Matches the Author filter only against the main author, not a co-author" do
      co_author = create(:user, :content_creator, first_name: "Grace", last_name: "Hopper")
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "Co-Authored Post")
      post.blog_post_authors.create!(user: co_author)

      visit filter_blog_posts_path(author_id: co_author.id)

      expect(page).not_to have_content("Co-Authored Post")
    end

    it "Matches CONTAINS case-insensitively in SQL mode" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Learning RAILS Deeply")

      visit filter_blog_posts_path(mode: "sql", query: 'title CONTAINS "rails"')

      expect(page).to have_content("Learning RAILS Deeply")
    end

    it "Combines Author and Published — the exact shape the 'My Posts' nav links use" do
      other_author = create(:user, :content_creator, first_name: "Grace", last_name: "Hopper")
      create(:blog_post, user: other_author, title: "Someone Else's Draft")
      create(:blog_post, user: owner, title: "My Own Draft")

      sign_in_as(owner)
      visit filter_blog_posts_path(author_id: owner.id, published: "draft")

      expect(page).to have_content("My Own Draft")
      expect(page).not_to have_content("Someone Else's Draft")
    end

    it "Keeps a post with no Category/Subject/Topic filterable via the 'All ...' defaults" do
      create(:blog_post, :unrestricted, :published, user: owner, title: "Bare Post").tap do |post|
        post.update_column(:blog_category_id, nil)
      end

      visit filter_blog_posts_path

      expect(page).to have_content("Bare Post")
      expect(page).to have_selector("[data-testid='filter-post-category']", text: "(Uncategorized)")
    end
  end
end
