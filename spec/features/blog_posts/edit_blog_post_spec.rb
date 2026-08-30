# spec/features/blog_posts/edit_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Edit blog post", type: :feature do
  let(:owner)   { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }
  let(:curtis)  { create(:user, :content_creator) }

  before do
    create(:contact, user: owner, contact: chris, status: "confirmed")
  end

  def fill_title(value)
    find("[data-testid='title-field']").set(value)
  end

  # See create_blog_post_spec.rb for why this exists instead of a plain
  # sign_in_as — occasional headless-Chrome strain over a long run, not
  # anything specific to this spec.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 3)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Updates the title and redirects to the show page" do
      post = create(:blog_post, user: owner, title: "Old Title")
      sign_in_as(owner)
      visit edit_blog_post_path(post)
      fill_title("New Title")
      click_button "Update Blog Post"
      post.reload

      expect(page).to have_current_path(blog_post_path(post))
      expect(page).to have_content("Blog post updated")
      expect(post.title).to eq("New Title")
    end

    it "Reverts a published post to Draft after any edit" do
      category = create(:blog_category)
      post = create(:blog_post, :published, user: owner, blog_category: category, body: "Content.")
      sign_in_as(owner)
      visit edit_blog_post_path(post)
      fill_title("Edited Title")
      click_button "Update Blog Post"

      expect(post.reload.published_at).to be_nil
    end

    it "Pre-populates the form with the post's current values" do
      post = create(:blog_post, user: owner, title: "Existing", subject: "Ruby", topic: "Rails")
      sign_in_as(owner)
      visit edit_blog_post_path(post)

      expect(find("[data-testid='title-field']").value).to eq("Existing")
      expect(find("[data-testid='subject-field']").value).to eq("Ruby")
      expect(find("[data-testid='topic-field']").value).to eq("Rails")
    end

    it "Pre-populates the shuttle with existing co-authors as Selected" do
      post = create(:blog_post, user: owner)
      post.blog_post_authors.create!(user: chris)
      sign_in_as(owner)
      visit edit_blog_post_path(post)

      within("[data-testid='selected-authors']") do
        expect(page).to have_content(chris.first_name)
      end
      within("[data-testid='available-authors']") do
        expect(page).not_to have_content(chris.first_name)
      end
    end

    context "With JavaScript", js: true do
      it "Adds a new co-author via the shuttle" do
        post = create(:blog_post, user: owner)
        sign_in_and_settle(owner)
        visit edit_blog_post_path(post)

        within("[data-testid='available-authors']") do
          find("option[value='#{chris.id}']").click
        end
        find("[data-testid='add-author-button']").click
        click_button "Update Blog Post"

        # The Formatted tab (default) intercepts submit to run an async
        # Markdown conversion before actually resubmitting — wait for that to
        # finish (via real page assertions) before reading DB state, or this
        # can race ahead of the real request the same way it did for
        # create_blog_post_spec.rb's equivalent test.
        expect(page).to have_current_path(blog_post_path(post))
        expect(page).to have_content("Blog post updated")
        expect(post.reload.authors).to contain_exactly(owner, chris)
      end

      it "Removes an existing co-author via the shuttle" do
        post = create(:blog_post, user: owner)
        post.blog_post_authors.create!(user: chris)
        sign_in_and_settle(owner)
        visit edit_blog_post_path(post)

        within("[data-testid='selected-authors']") do
          find("option[value='#{chris.id}']").click
        end
        find("[data-testid='remove-author-button']").click
        click_button "Update Blog Post"

        expect(page).to have_current_path(blog_post_path(post))
        expect(page).to have_content("Blog post updated")
        expect(post.reload.authors).to contain_exactly(owner)
      end

      it "Seeds the Formatted tab with the post's existing content" do
        post = create(:blog_post, user: owner, body: "# Existing Heading")
        sign_in_and_settle(owner)
        visit edit_blog_post_path(post)

        within("[data-testid='quill-editor']") do
          expect(page).to have_css("h1", text: "Existing Heading")
        end
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page" do
      post = create(:blog_post, :unrestricted, user: owner)
      visit edit_blog_post_path(post)
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies a stranger and makes no changes" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "Untouched")
      stranger = create(:user, :content_creator)
      sign_in_as(stranger)
      visit edit_blog_post_path(post)

      expect(page).to have_current_path(blog_post_path(post))
      expect(page).to have_content("Not authorised")
      expect(post.reload.title).to eq("Untouched")
    end

    it "Never adds a non-confirmed-contact as a co-author even if forged into the request", js: true do
      post = create(:blog_post, user: owner)
      sign_in_and_settle(owner)
      visit edit_blog_post_path(post)

      page.execute_script(<<~JS, curtis.id)
        const option = document.createElement("option")
        option.value = arguments[0]
        option.text = "Forged Author"
        document.querySelector("[data-testid='selected-authors']").appendChild(option)
      JS

      click_button "Update Blog Post"

      expect(page).to have_current_path(blog_post_path(post))
      expect(page).to have_content("Blog post updated")
      expect(post.reload.authors).not_to include(curtis)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows a co-author (not the primary author) to edit" do
      post = create(:blog_post, user: owner, title: "Old Title")
      post.blog_post_authors.create!(user: chris)
      sign_in_as(chris)
      visit edit_blog_post_path(post)
      fill_title("Updated by Co-Author")
      click_button "Update Blog Post"

      expect(post.reload.title).to eq("Updated by Co-Author")
    end

    it "Allows 'Adam Admin' to edit any post" do
      post = create(:blog_post, user: owner, title: "Old Title")
      sign_in_as(create(:user, :admin))
      visit edit_blog_post_path(post)
      fill_title("Updated by Admin")
      click_button "Update Blog Post"

      expect(post.reload.title).to eq("Updated by Admin")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Leaves a draft as a draft after editing" do
      post = create(:blog_post, user: owner, title: "Old Title")
      sign_in_as(owner)
      visit edit_blog_post_path(post)
      fill_title("New Title")
      click_button "Update Blog Post"

      expect(post.reload.published_at).to be_nil
    end

    it "Never removes the primary author's own row even if the shuttle is emptied out", js: true do
      post = create(:blog_post, user: owner)
      sign_in_and_settle(owner)
      visit edit_blog_post_path(post)

      page.execute_script(<<~JS)
        document.querySelector("[data-testid='selected-authors']").innerHTML = ""
      JS

      click_button "Update Blog Post"

      expect(page).to have_current_path(blog_post_path(post))
      expect(page).to have_content("Blog post updated")
      expect(post.reload.authors).to contain_exactly(owner)
    end
  end
end
