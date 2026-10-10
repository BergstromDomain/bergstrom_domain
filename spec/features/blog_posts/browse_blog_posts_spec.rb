# spec/features/blog_posts/browse_blog_posts_spec.rb

require "rails_helper"

RSpec.describe "Browse Blog Posts", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
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
      expect(page).to have_selector("[data-testid='browse-breadcrumb-current']", text: "Ruby On Rails")
      expect(page).to have_selector("[data-testid='browse-post-card']", count: 3)
    end

    it "Shows a Category's Subjects above a preview panel of every post in the Category" do
      visit blog_posts_path(category_id: technology.slug)

      expect(page).to have_selector("[data-testid='browse-tree'] + [data-testid='browse-preview']")
      within("[data-testid='browse-preview']") do
        expect(page).to have_selector("[data-testid='browse-preview-heading']", text: "Posts in Technology (5)")
        expect(page).to have_selector("[data-testid='browse-post-card']", count: 5)
      end
    end

    it "Shows a Subject's Topics above a preview panel of every post with that Subject" do
      visit blog_posts_path(category_id: technology.slug, subject: "Software Development")

      within("[data-testid='browse-preview']") do
        expect(page).to have_selector("[data-testid='browse-preview-heading']", text: "Posts in Software Development (4)")
        expect(page).to have_selector("[data-testid='browse-post-card']", count: 4)
      end
    end

    it "Shows no preview panel at the root level" do
      visit blog_posts_path
      expect(page).to have_no_selector("[data-testid='browse-preview']")
    end

    it "Displays the correct fields on each post card" do
      java_post.likes.create!(user: create(:user), face: "neutral")
      create_list(:comment, 2, commentable: java_post)
      visit blog_posts_path(category_id: technology.slug, subject: "Software Development", topic: "Java")

      card = find("[data-testid='browse-post-card']")
      within(card) do
        expect(page).to have_selector("h2", text: "Java Basics")
        expect(page).to have_link("Java Basics", href: blog_post_path(java_post))
        expect(page).to have_selector("[data-testid='browse-post-author']", text: "#{owner.first_name} #{owner.last_name}")
        expect(page).to have_selector("[data-testid='browse-post-created']", text: java_post.created_at.strftime("%d-%b-%Y"))
        expect(page).to have_selector("[data-testid='browse-post-path']", text: "Technology » Software Development » Java")
        expect(page).to have_selector("[data-testid='browse-post-meta-left']", text: "Filed Under: Technology » Software Development » Java")
        within("[data-testid='browse-post-meta-right']") do
          expect(page).to have_content("Author:")
          expect(page).to have_content("Created:")
          expect(page).to have_content("Reactions:")
          expect(page).to have_content("Comments:")
        end
        expect(page).to have_content("Reactions:")
        expect(page).to have_no_content("Likes:")
        expect(page).to have_selector("[data-testid='browse-post-smiles']", text: "3.0")
        expect(page).to have_selector("[data-testid='browse-post-comments']", text: "2")
        expect(page).to have_selector("[data-testid='browse-post-teaser']", text: "A" * 197 + "...")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Never counts a restricted post in a guest's Category totals" do
      category = create(:blog_category, name: "Secrets")
      create(:blog_post, :restricted, :published, user: owner, blog_category: category)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Chronicle (0)", href: blog_posts_path)
        expect(page).to have_link("Secrets (0)")
      end
    end

    it "Never counts or lists a soft-deleted post, even one still in its admin-restorable window" do
      category = create(:blog_category, name: "Has A Deleted Post")
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category)
      post.update!(deleted_at: Time.current)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Chronicle (0)", href: blog_posts_path)
        expect(page).to have_link("Has A Deleted Post (0)")
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
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

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Lists a post with no Subject/Topic in the parent's preview panel, with no '(No ...)' entry" do
      category = create(:blog_category, name: "Mixed")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        subject: nil, topic: nil, title: "Bare Post")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        subject: "Ruby", topic: nil, title: "Ruby Post")

      visit blog_posts_path(category_id: category.slug)
      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Ruby (1)")
        expect(page).to have_no_link(text: /No Subject/)
      end
      within("[data-testid='browse-preview']") { expect(page).to have_content("Bare Post") }

      visit blog_posts_path(category_id: category.slug, subject: "Ruby")
      within("[data-testid='browse-tree']") { expect(page).to have_no_link(text: /No Topic/) }
      within("[data-testid='browse-preview']") { expect(page).to have_content("Ruby Post") }
    end

    it "Leaves a missing Subject/Topic out of a card's Category path" do
      category = create(:blog_category, name: "Mixed")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category, subject: nil, topic: nil)

      visit blog_posts_path(category_id: category.slug)

      expect(find("[data-testid='browse-post-path']").text).to eq("Mixed")
    end

    it "Orders the preview panel newest first" do
      category = create(:blog_category, name: "Ordered")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        title: "Older Post", created_at: 2.days.ago)
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        title: "Newer Post", created_at: 1.day.ago)

      visit blog_posts_path(category_id: category.slug)

      titles = page.all("[data-testid='browse-post-title']").map(&:text)
      expect(titles).to eq([ "Newer Post", "Older Post" ])
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

    it "Shows every Blog Category, including one with zero (visible) posts, alongside a populated one" do
      create(:blog_category, name: "Empty Category")
      has_posts = create(:blog_category, name: "Has Posts")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: has_posts)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Has Posts (1)")
        expect(page).to have_link("Empty Category (0)")
      end
    end

    it "Bolds a Category's link when it has posts, but not an empty one" do
      create(:blog_category, name: "Empty Category")
      has_posts = create(:blog_category, name: "Has Posts")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: has_posts)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_link("Has Posts (1)", href: blog_posts_path(category_id: has_posts.slug))
        expect(page).to have_css("a.browse-tree__link--has-posts", text: "Has Posts (1)")
        expect(page).to have_no_css("a.browse-tree__link--has-posts", text: "Empty Category (0)")
      end
    end

    it "Never shows an '(Uncategorized)' entry" do
      category = create(:blog_category, name: "Has A Post")
      create(:blog_post, :unrestricted, :published, user: owner, blog_category: category)

      visit blog_posts_path

      within("[data-testid='browse-tree']") do
        expect(page).to have_no_link(text: /Uncategorized/)
      end
    end

    it "Redirects an unknown Category back to the Browse root" do
      visit blog_posts_path(category_id: "none")
      expect(page).to have_current_path(blog_posts_path)
    end
  end
end
