# spec/features/blog_posts/browse_blog_posts_spec.rb

require "rails_helper"

RSpec.describe "Browse blog posts", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    let!(:food)       { create(:blog_category, name: "Food") }
    let!(:technology) { create(:blog_category, name: "Technology") }
    let!(:java_post) do
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: technology,
        subject: "Software Development", topic: "Java", title: "Java Basics",
        body: "A" * 250)
    end

    before do
      create_list(:blog_post, 5, :unrestricted, :published, user: owner, blog_category: food)
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: technology, subject: "Network")
      create_list(:blog_post, 3, :unrestricted, :published, user: owner, blog_category: technology,
        subject: "Software Development", topic: "Ruby On Rails")
    end

    it "Shows the static heading and a Chronicle root link with the total count" do
      visit blog_posts_path

      expect(page).to have_selector("[data-testid='browse-root']", text: "Browse Blog Posts")
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Chronicle (10)", href: blog_posts_path)
        expect(page).to have_link("Food (5)")
        expect(page).to have_link("Technology (5)")
      end
    end

    it "Drills into a Category and shows only that Category with its Subjects nested" do
      visit blog_posts_path
      click_link "Technology (5)"

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Technology (5)")
        expect(page).not_to have_link(text: /^Food/)
        expect(page).to have_link("Network (1)")
        expect(page).to have_link("Software Development (4)")
      end
    end

    it "Drills into a Subject and shows only its Topics nested" do
      visit blog_posts_path(category_id: technology.slug, subject: "Software Development")

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Technology (5)")
        expect(page).to have_link("Software Development (4)")
        expect(page).not_to have_link(text: /^Network/)
        expect(page).to have_link("Java (1)")
        expect(page).to have_link("Ruby On Rails (3)")
      end
    end

    it "Navigates back up to the root via the Chronicle link after drilling into a Category" do
      visit blog_posts_path(category_id: technology.slug)
      within("[data-testid='browse-tree']") { click_link "Chronicle (10)" }

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Food (5)")
        expect(page).to have_link("Technology (5)")
      end
    end

    it "Drills into a Topic and shows a breadcrumb and a card per post" do
      visit blog_posts_path(category_id: technology.slug, subject: "Software Development", topic: "Ruby On Rails")

      expect(page).to have_selector("[data-testid='browse-breadcrumb']", text: "Technology")
      expect(page).to have_selector("[data-testid='browse-breadcrumb']", text: "Software Development")
      expect(page).to have_selector("[data-testid='browse-breadcrumb-topic']", text: "Ruby On Rails")
      expect(page).to have_selector("[data-testid='browse-post-card']", count: 3)
    end

    it "Displays the correct fields on each post card" do
      visit blog_posts_path(category_id: technology.slug, subject: "Software Development", topic: "Java")

      card = find("[data-testid='browse-post-card']")
      within(card) do
        expect(page).to have_selector("h2", text: "Java Basics")
        expect(page).to have_link("Java Basics", href: blog_post_path(java_post))
        expect(page).to have_selector("[data-testid='browse-post-author']", text: "#{owner.first_name} #{owner.last_name}")
        expect(page).to have_selector("[data-testid='browse-post-created']", text: java_post.created_at.strftime("%d-%b-%Y"))
        expect(page).to have_selector("[data-testid='browse-post-smiles']", text: "3.0")
        expect(page).to have_selector("[data-testid='browse-post-teaser']", text: "A" * 197 + "...")
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Never counts a restricted post in a guest's Category totals" do
      category = create(:blog_category, name: "Secrets")
      create(:blog_post, :restricted, :published, user: owner, blog_category: category)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Chronicle (0)", href: blog_posts_path)
        expect(page).not_to have_link(text: /Secrets/)
      end
    end

    it "Never shows an empty bucket in the tree at all" do
      create(:blog_category, name: "Empty Category")
      has_posts = create(:blog_category, name: "Has Posts")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: has_posts)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Has Posts (1)")
        expect(page).not_to have_link(text: /Empty Category/)
      end
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets 'Adam Admin' see drafts and restricted posts in the counts" do
      category = create(:blog_category, name: "Admin Only")
      create(:blog_post, :restricted, user: owner, blog_category: category, title: "Unpublished Draft")

      sign_in_as(create(:user, :admin))
      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Admin Only (1)")
      end
    end

    it "Lets a signed-in author see their own unpublished draft's Category in the counts" do
      category = create(:blog_category, name: "My Drafts")
      create(:blog_post, user: owner, blog_category: category, title: "My Own Draft")

      sign_in_as(owner)
      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("My Drafts (1)")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Buckets a post with no Category under '(Uncategorized)' and it's reachable through it" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "Homeless Post")
      # A published post always needs a Category (Block 4 validation) — force
      # it uncategorized at the DB level, bypassing validation, purely to
      # exercise this display branch.
      post.update_column(:blog_category_id, nil)

      visit blog_posts_path
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("(Uncategorized) (1)")
        click_link "(Uncategorized) (1)"
      end

      expect(page).to have_selector("[data-testid='browse-tree']", text: "(No Subject)")
    end

    it "Buckets a post missing only Subject/Topic under '(No Subject)'/'(No Topic)'" do
      category = create(:blog_category, name: "Mixed")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category, subject: nil, topic: nil)

      visit blog_posts_path(category_id: category.slug)
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("(No Subject) (1)")
        click_link "(No Subject) (1)"
      end

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("(No Topic) (1)")
      end
    end

    it "Navigates back to the correct intermediate level via a breadcrumb link" do
      category = create(:blog_category, name: "Technology")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        subject: "Software Development", topic: "Ruby On Rails")

      visit blog_posts_path(category_id: category.slug, subject: "Software Development", topic: "Ruby On Rails")
      within("[data-testid='browse-breadcrumb']") { click_link "Technology" }

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Software Development (1)")
      end
    end

    it "Falls back to a generic icon for a card whose post has neither an image nor a Category" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "Bare Post")
      post.update_column(:blog_category_id, nil)

      visit blog_posts_path(category_id: "none", subject: "none", topic: "none")

      within("[data-testid='browse-post-card']") do
        expect(page).to have_selector(".event-type-icon-large svg")
      end
    end
  end
end
