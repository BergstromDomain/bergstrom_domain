# spec/features/blog_posts/create_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Create blog post", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:curtis)  { create(:user, :content_creator) }

  before do
    create(:contact, user: charlie, contact: chris, status: "confirmed")
  end

  def fill_title(value)
    find("[data-testid='title-field']").set(value)
  end

  # sign_in_as's final click triggers a server-side redirect; without an
  # explicit settle point here, a `visit` called immediately afterwards can
  # race that redirect in a real (Selenium) browser. Settles on rendered
  # content (the authenticated top-nav dropdown), not `current_path` — the
  # latter can read back a stale pre-redirect URL even once the actual
  # post-redirect page has rendered. Occasionally the click doesn't visibly
  # progress past the form at all (no flash, no redirect) — likely headless
  # Chrome strain over a long full-suite run rather than anything about this
  # spec specifically (this app already carries several `xit`-skipped specs
  # for the same class of flakiness); retrying the whole sign-in a couple of
  # times clears most of those without masking a real, persistent failure.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 3)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # The Raw <-> Formatted conversion round-trips through an async fetch to
  # #convert_format, so reading the textarea's value right after a tab click
  # can race ahead of it — poll instead of reading .value once immediately,
  # both for a correct assertion and so this example doesn't leave a pending
  # fetch running into whatever example starts next.
  def wait_for_raw_value(includes:)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        value = find("[data-testid='body-field']").value
        return value if Array(includes).all? { |s| value.include?(s) }
        sleep 0.05
      end
    end
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    before { sign_in_and_settle(charlie) }

    it "Creates a blog post as a draft and redirects to Chronicle" do
      visit new_blog_post_path
      fill_title("My First Post")
      find("[data-testid='sub-category-field']").set("Ruby")
      find("[data-testid='topic-field']").set("Rails")
      click_button "Save Blog Post"

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("Blog post saved as a draft")

      post = BlogPost.find_by(title: "My First Post")
      expect(post).to be_present
      expect(post.published_at).to be_nil
      expect(post.user).to eq(charlie)
    end

    it "Automatically adds the creator as an author" do
      visit new_blog_post_path
      fill_title("My First Post")
      click_button "Save Blog Post"

      post = BlogPost.find_by(title: "My First Post")
      expect(post.authors).to contain_exactly(charlie)
    end

    it "Allows the Category to be left blank" do
      visit new_blog_post_path
      fill_title("Uncategorised Post")
      click_button "Save Blog Post"

      post = BlogPost.find_by(title: "Uncategorised Post")
      expect(post.blog_category).to be_nil
    end

    it "Only lists confirmed contacts in the Available authors list" do
      visit new_blog_post_path
      within("[data-testid='available-authors']") do
        expect(page).to have_content(chris.first_name)
        expect(page).not_to have_content(curtis.first_name)
      end
    end

    context "With JavaScript", js: true do
      it "Adds a confirmed contact as a co-author via the shuttle" do
        visit new_blog_post_path
        fill_title("Co-Authored Post")

        within("[data-testid='available-authors']") do
          find("option", text: "#{chris.first_name} #{chris.last_name}").click
        end
        find("[data-testid='add-author-button']").click

        within("[data-testid='selected-authors']") do
          expect(page).to have_content(chris.first_name)
        end

        click_button "Save Blog Post"

        expect(page).to have_current_path(chronicle_path)
        post = BlogPost.find_by(title: "Co-Authored Post")
        expect(post.authors).to contain_exactly(charlie, chris)
      end

      it "Round-trips content between the Raw and Formatted tabs" do
        visit new_blog_post_path
        fill_title("Round Trip Post")
        find("[data-testid='raw-tab']").click
        find("[data-testid='body-field']").set("# Hello\n\nWorld")

        find("[data-testid='formatted-tab']").click
        within("[data-testid='quill-editor']") do
          expect(page).to have_css("h1", text: "Hello")
          expect(page).to have_content("World")
        end

        find("[data-testid='raw-tab']").click
        expect(wait_for_raw_value(includes: %w[Hello World])).to include("Hello").and include("World")
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      visit new_blog_post_path
      expect(page).to have_current_path(new_session_path)
    end

    context "As 'Charlie Content Creator'" do
      before { sign_in_as(charlie) }

      it "Shows an error when title is missing" do
        visit new_blog_post_path
        click_button "Save Blog Post"

        expect(page).to have_selector("[data-testid='field-error']")
        expect(page).to have_content("can't be blank")
        expect(BlogPost.count).to eq(0)
      end

      it "Shows an error when the title is already used by the same user" do
        create(:blog_post, user: charlie, title: "Existing Post")
        visit new_blog_post_path
        fill_title("Existing Post")
        click_button "Save Blog Post"

        expect(page).to have_content("has already been taken")
        expect(BlogPost.where(title: "Existing Post").count).to eq(1)
      end

      it "Allows two different users to share the same title" do
        create(:blog_post, user: chris, title: "Shared Title")
        visit new_blog_post_path
        fill_title("Shared Title")
        click_button "Save Blog Post"

        expect(page).to have_current_path(chronicle_path)
        expect(BlogPost.where(title: "Shared Title").count).to eq(2)
      end

      it "Shows an error when Topic is set without Sub Category" do
        visit new_blog_post_path
        fill_title("Bad Topic Post")
        find("[data-testid='topic-field']").set("Rails")
        click_button "Save Blog Post"

        expect(page).to have_content("must be present if Topic is set")
        expect(BlogPost.count).to eq(0)
      end
    end

    it "Redirects 'Uno User' (app_user role) to Chronicle" do
      sign_in_as(create(:user, :app_user))
      visit new_blog_post_path
      expect(page).to have_current_path(chronicle_path)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows 'Adam Admin' to create a blog post" do
      sign_in_as(create(:user, :admin))
      visit new_blog_post_path
      fill_title("Admin Post")
      click_button "Save Blog Post"

      expect(page).to have_current_path(chronicle_path)
      expect(BlogPost.find_by(title: "Admin Post")).to be_present
    end

    it "Re-renders the form with entered values when validation fails" do
      sign_in_as(charlie)
      visit new_blog_post_path
      find("[data-testid='sub-category-field']").set("Ruby")
      click_button "Save Blog Post"

      expect(find("[data-testid='sub-category-field']").value).to eq("Ruby")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    before { sign_in_and_settle(charlie) }

    it "Never creates a BlogPostAuthor for a non-confirmed-contact even if their id is submitted directly", js: true do
      visit new_blog_post_path
      fill_title("Tampered Post")

      page.execute_script(<<~JS, curtis.id)
        const option = document.createElement("option")
        option.value = arguments[0]
        option.text = "Forged Author"
        document.querySelector("[data-testid='selected-authors']").appendChild(option)
      JS

      click_button "Save Blog Post"

      expect(page).to have_current_path(chronicle_path)
      post = BlogPost.find_by(title: "Tampered Post")
      expect(post.authors).not_to include(curtis)
    end

    it "Handles a long title without breaking the page" do
      visit new_blog_post_path
      fill_title("A" * 60)
      click_button "Save Blog Post"

      expect(page).to have_current_path(chronicle_path)
    end
  end
end
