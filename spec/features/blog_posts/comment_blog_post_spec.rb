# spec/features/blog_posts/comment_blog_post_spec.rb

require "rails_helper"

RSpec.describe "Comment on blog post", type: :feature do
  let(:owner)  { create(:user, :content_creator) }
  let(:reader) { create(:user, :content_creator) }

  def published_post(**attrs)
    create(:blog_post, :unrestricted, :published, user: owner, **attrs)
  end

  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 3)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # Sets a Trix editor's content by driving Trix's own document API
  # (editor.setSelectedRange + editor.insertString) via execute_script, rather
  # than Capybara's `.set()`, which drives a contenteditable element through
  # synthetic keystrokes (select-all, delete, type). That keystroke simulation
  # proved unreliable specifically when replacing a *non-empty* editor (e.g.
  # editing an existing comment) under full-suite-only conditions — confirmed
  # by direct evidence, not guesswork: a temporary diagnostic dump showed
  # `.set()` returning normally with focus correctly on the trix-editor and
  # Trix fully initialized, yet the visible editor's content was completely
  # unchanged (still the pre-existing text). Driving Trix's API directly
  # sidesteps whatever makes the synthetic-keystroke clear-and-type path
  # unreliable, since it mutates the document model the same way Trix's own
  # toolbar/attachment code does, which is what actually fires the
  # "trix-change" event syncing the paired hidden input.
  def set_trix(selector, text)
    field = find(selector, visible: true, wait: 10)
    page.execute_script(<<~JS, field["id"], text)
      const editor = document.getElementById(arguments[0]).editor
      editor.setSelectedRange([0, editor.getDocument().toString().length])
      editor.insertString(arguments[1])
    JS
    expect(page).to have_field(field["input"], type: :hidden, with: /#{Regexp.escape(text)}/, wait: 10)
  end

  # `within(scope) { click_button(...) }` re-resolves `scope` and the button
  # inside it right when the block runs — same class of staleness this file
  # already works around for `find` right after a JS-driven reveal (see
  # sign_in_and_settle/set_trix above): finding the exact scoped element
  # directly, rather than through `within`, is what's proven reliable here.
  def click_submit_within(scope_selector)
    find("#{scope_selector} input[type='submit']", visible: true).click
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Posts a top-level comment and shows the correct count", js: true do
      post = published_post
      sign_in_and_settle(reader)
      visit blog_post_path(post)

      set_trix("[data-testid='comment-body-field']", "A great post!")

      click_button "Post"

      expect(page).to have_selector("[data-testid='comment-body']", text: "A great post!")
      expect(page).to have_selector("[data-testid='comments-count']", text: "1 comment in 1 thread")
    end

    it "Shows the newest top-level comment on top, oldest at the bottom" do
      post = published_post
      create(:comment, blog_post: post, user: owner, body: "First comment", created_at: 2.days.ago)
      create(:comment, blog_post: post, user: owner, body: "Second comment", created_at: 1.day.ago)

      sign_in_as(reader)
      visit blog_post_path(post)

      expect(page.text.index("Second comment")).to be < page.text.index("First comment")
    end

    it "Replies to a comment, indenting it under that thread", js: true do
      post = published_post
      thread = create(:comment, blog_post: post, user: owner, body: "Original comment")
      sign_in_and_settle(reader)
      visit blog_post_path(post)

      find("[data-testid='reply-link-#{thread.id}']").click
      set_trix("[data-testid='reply-toggle-#{thread.id}'] [data-testid='comment-body-field']", "A reply!")

      click_submit_within("[data-testid='reply-toggle-#{thread.id}']")

      expect(page).to have_selector("[data-testid='comments-count']", text: "2 comments in 1 thread")
      expect(page).to have_selector("[data-testid='reply-#{thread.reload.replies.last.id}']")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Redirects 'Gary Guest' to the 'Sign in' page on a direct comment request" do
      post = published_post
      page.driver.submit :post, blog_post_comments_path(post), { comment: { body: "Hi" } }
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies commenting on a post the user cannot read" do
      post = create(:blog_post, :restricted, user: owner)
      sign_in_as(reader)
      page.driver.submit :post, blog_post_comments_path(post), { comment: { body: "Hi" } }

      expect(page).to have_content("Not authorised")
      expect(post.reload.comments).to be_empty
    end

    it "Does not show Reply/Edit/Delete actions to a guest" do
      post = published_post
      create(:comment, blog_post: post, user: owner, body: "A comment")
      visit blog_post_path(post)

      expect(page).not_to have_button("Reply")
      expect(page).not_to have_button("Edit")
      expect(page).not_to have_button("Delete")
    end

    it "Denies editing someone else's comment" do
      post = published_post
      comment = create(:comment, blog_post: post, user: owner, body: "Original")
      sign_in_as(reader)
      page.driver.submit :patch, comment_path(comment), { comment: { body: "Hacked" } }

      expect(page).to have_content("Not authorised")
      expect(comment.reload.body.to_plain_text).to eq("Original")
    end

    it "Denies deleting someone else's comment" do
      post = published_post
      comment = create(:comment, blog_post: post, user: owner, body: "Original")
      sign_in_as(reader)
      page.driver.submit :delete, comment_path(comment), {}

      expect(page).to have_content("Not authorised")
      expect(Comment.exists?(comment.id)).to be true
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Allows an admin to delete any comment" do
      post = published_post
      comment = create(:comment, blog_post: post, user: reader, body: "Some comment")
      sign_in_as(create(:user, :admin))
      visit blog_post_path(post)

      find("[data-testid='delete-comment-#{comment.id}']").click

      expect(page).to have_content("Comment deleted")
      expect(Comment.exists?(comment.id)).to be false
    end

    it "Lets the author edit their own comment in place", js: true do
      post = published_post
      comment = create(:comment, blog_post: post, user: reader, body: "Original text")
      sign_in_and_settle(reader)
      visit blog_post_path(post)

      find("[data-testid='edit-link-#{comment.id}']").click
      # Unlike a brand-new/empty comment or reply editor, this one loads with
      # existing rich-text content — wait for Trix's own async parse of that
      # initial document to finish rendering before overwriting it, or set_trix's
      # focus+set can race Trix's own initialization of the pre-existing content.
      expect(page).to have_selector("[data-testid='edit-toggle-#{comment.id}'] [data-testid='comment-body-field']",
        text: "Original text")
      set_trix("[data-testid='edit-toggle-#{comment.id}'] [data-testid='comment-body-field']", "Updated text")

      click_submit_within("[data-testid='edit-toggle-#{comment.id}']")

      # Confirm the post-submit navigation has actually landed (the old
      # edit form is gone) before checking the new body text — a resource-
      # starved full-suite run can make this specific full-page Turbo
      # navigation take longer than Capybara's default wait, and unlike
      # Create/Reply (whose assertions match brand-new text with no stale
      # match to land on first), this selector already matches an element on
      # the pre-navigation page, so an under-waited check can appear to have
      # "found" something and fail on the old value instead of retrying long
      # enough to see the new page.
      expect(page).to have_no_selector("[data-testid='edit-toggle-#{comment.id}'] [data-testid='comment-body-field']",
        wait: 10)
      expect(page).to have_selector("[data-testid='comment-body']", text: "Updated text", wait: 10)
      expect(comment.reload.body.to_plain_text).to eq("Updated text")
    end

    it "Displays an image attached to a comment (rich text, not Markdown)" do
      post = published_post
      blob = ActiveStorage::Blob.create_and_upload!(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "test_image.jpg",
        content_type: "image/jpeg"
      )
      body = ActionText::Content.new.append_attachables(blob)
      create(:comment, blog_post: post, user: owner, body: body)

      visit blog_post_path(post)

      within("[data-testid='comment-body']") do
        expect(page).to have_selector("img")
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Deletes all replies when the top-level comment is deleted, updating the count" do
      post = published_post
      thread = create(:comment, blog_post: post, user: owner, body: "Original")
      create(:comment, blog_post: post, user: owner, parent: thread, body: "A reply")
      sign_in_as(owner)
      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='comments-count']", text: "2 comments in 1 thread")
      find("[data-testid='delete-comment-#{thread.id}']").click

      expect(page).to have_selector("[data-testid='comments-count']", text: "0 comments in 0 threads")
      expect(Comment.count).to eq(0)
    end

    it "Flattens a reply-to-a-reply onto the same thread instead of nesting further" do
      post = published_post
      thread = create(:comment, blog_post: post, user: owner, body: "Original")
      reply = create(:comment, blog_post: post, user: owner, parent: thread, body: "A reply")
      sign_in_as(reader)

      page.driver.submit :post, blog_post_comments_path(post),
        { comment: { body: "Reply to a reply", parent_id: reply.id } }

      new_comment = Comment.order(:created_at).last
      expect(new_comment.body.to_plain_text).to eq("Reply to a reply")
      expect(new_comment.parent_id).to eq(thread.id)
    end
  end
end
