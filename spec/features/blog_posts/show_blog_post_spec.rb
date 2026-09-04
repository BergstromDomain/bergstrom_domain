# spec/features/blog_posts/show_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Show blog post", type: :feature do
  let(:owner)  { create(:user, :content_creator) }
  let(:admin)  { create(:user, :admin) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    let(:category) { create(:blog_category, name: "Technology", icon: "cpu", description: "Tech posts.") }
    let!(:post) do
      create(:blog_post, :unrestricted, :published,
        user:             owner,
        title:            "My Great Post",
        body:             "# Heading\n\nSome **bold** text.",
        blog_category:    category,
        subject:          "Ruby",
        topic:            "Rails")
    end

    before { visit blog_post_path(post) }

    it "Displays the post title" do
      expect(page).to have_selector("[data-testid='blog-post-title']", text: "My Great Post")
    end

    it "Renders the body as formatted HTML" do
      expect(page).to have_selector("h1", text: "Heading")
      expect(page).to have_selector("strong", text: "bold")
    end

    it "Displays the Category, Subject, and Topic" do
      expect(page).to have_selector("[data-testid='blog-post-category']", text: "Technology")
      expect(page).to have_selector("[data-testid='blog-post-subject']", text: "Ruby")
      expect(page).to have_selector("[data-testid='blog-post-topic']", text: "Rails")
    end

    it "Links the Category to its show page" do
      expect(page).to have_link("Technology", href: blog_category_path(category))
    end

    it "Displays the category icon as a fallback when no blog image is attached" do
      expect(page).to have_selector("[data-testid='blog-post-category-icon'] svg")
      expect(page).not_to have_selector("[data-testid='blog-post-image']")
    end

    it "Displays the author" do
      expect(page).to have_selector("[data-testid='blog-post-authors']",
                               text: "#{owner.first_name} #{owner.last_name}")
    end

    it "Displays the comment count and the default like score" do
      expect(page).to have_selector("[data-testid='blog-post-comments-count']", text: "0")
      # No one has explicitly reacted yet, so the score is the neutral baseline.
      expect(page).to have_selector("[data-testid='blog-post-likes-count']", text: "3.0")
    end

    it "Shows a back link to Chronicle" do
      expect(page).to have_link("Back to Chronicle", href: chronicle_path)
    end

    it "Is accessible by slug" do
      visit blog_post_path(post.slug)
      expect(page).to have_selector("[data-testid='blog-post-title']", text: "My Great Post")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns 404 for a non-existent slug" do
      visit blog_post_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end

    it "Redirects a stranger away from a restricted post" do
      post = create(:blog_post, :restricted, :published, user: owner)
      visit blog_post_path(post)
      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Redirects a non-contact away from a contacts-classified post" do
      stranger = create(:user, :content_creator)
      post = create(:blog_post, :contacts, :published, user: owner)
      sign_in_as(stranger)
      visit blog_post_path(post)
      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Redirects a stranger away from another author's unpublished draft" do
      post = create(:blog_post, :unrestricted, user: owner)
      stranger = create(:user, :content_creator)
      sign_in_as(stranger)
      visit blog_post_path(post)
      expect(page).to have_current_path(chronicle_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows 'Adam Admin' to view a restricted post" do
      post = create(:blog_post, :restricted, :published, user: owner, title: "Admin Viewable")
      sign_in_as(admin)
      visit blog_post_path(post)
      expect(page).to have_selector("[data-testid='blog-post-title']", text: "Admin Viewable")
    end

    it "Allows the author to view their own unpublished draft" do
      post = create(:blog_post, :unrestricted, user: owner, title: "My Draft")
      sign_in_as(owner)
      visit blog_post_path(post)
      expect(page).to have_selector("[data-testid='blog-post-title']", text: "My Draft")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Shows Category without Subject or Topic when neither is set" do
      category = create(:blog_category, name: "Cooking", icon: "chef-hat", description: "Cooking posts.")
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category)
      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='blog-post-category']", text: "Cooking")
      expect(page).not_to have_selector("[data-testid='blog-post-subject']")
      expect(page).not_to have_selector("[data-testid='blog-post-topic']")
    end

    it "Hides the Category section entirely and shows no icon when no Category is set" do
      # A published post always has a Category (required to publish, Block 4)
      # — a draft is the only state that can lack one, so it's what exercises
      # this display branch; the author views their own draft to see it.
      post = create(:blog_post, :unrestricted, user: owner, blog_category: nil)
      sign_in_as(owner)
      visit blog_post_path(post)

      expect(page).not_to have_selector("[data-testid='blog-post-category']")
      expect(page).not_to have_selector("[data-testid='blog-post-category-icon']")
      expect(page).not_to have_selector("[data-testid='blog-post-image']")
    end

    it "Strips a script tag out of the rendered body" do
      post = create(:blog_post, :unrestricted, :published, user: owner,
        body: "Hello <script>alert('xss')</script> World")
      visit blog_post_path(post)

      within("[data-testid='show-panel-main']") do
        expect(page).to have_content("Hello")
        expect(page).to have_content("World")
        expect(page).not_to have_selector("script", visible: :all)
      end
    end

    it "Renders a fenced code block with syntax highlighting" do
      post = create(:blog_post, :unrestricted, :published, user: owner,
        body: "```ruby\ndef foo\nend\n```")
      visit blog_post_path(post)

      within("[data-testid='show-panel-main']") do
        expect(page).to have_selector("pre[lang='ruby'] code span[style]")
      end
    end

    it "Displays an image embedded in the body (e.g. pasted into the Formatted editor)" do
      post = create(:blog_post, :unrestricted, :published, user: owner,
        body: "![A cat](https://example.com/cat.png)")
      visit blog_post_path(post)

      within("[data-testid='show-panel-main']") do
        expect(page).to have_selector("img[src='https://example.com/cat.png'][alt='A cat']")
      end
    end

    it "Displays a real uploaded blog image instead of the category icon fallback" do
      category = create(:blog_category, name: "Travel", icon: "plane", description: "Travel posts.")
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category)
      post.blog_image.attach(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "test_image.jpg",
        content_type: "image/jpeg"
      )

      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='blog-post-image'] img")
      expect(page).not_to have_selector("[data-testid='blog-post-category-icon']")
    end
  end
end
