# spec/features/recipes/comment_recipe_spec.rb

require "rails_helper"

RSpec.describe "Comment Recipe", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user, :app_user) }

  def published_recipe(**attrs)
    create(:recipe, :published, :unrestricted, user: charlie, **attrs)
  end

  # See comment_blog_post_spec.rb for why Trix is driven through its own API.
  def set_trix(selector, text)
    field = find(selector, visible: true, wait: 10)
    page.execute_script(<<~JS, field["id"], text)
      const editor = document.getElementById(arguments[0]).editor
      editor.setSelectedRange([0, editor.getDocument().toString().length])
      editor.insertString(arguments[1])
    JS
    expect(page).to have_field(field["input"], type: :hidden, with: /#{Regexp.escape(text)}/, wait: 10)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Posts a top-level comment and updates both counts", js: true do
      recipe = published_recipe
      sign_in_as(uno)
      expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 10)
      visit recipe_path(recipe)

      set_trix("[data-testid='comment-body-field']", "Lovely soup!")
      find("[data-testid='comments-panel'] input[type='submit']", visible: true).click

      expect(page).to have_selector("[data-testid='comment-body']", text: "Lovely soup!", wait: 10)
      expect(page).to have_selector("[data-testid='comments-count']", text: "1 comment in 1 thread")
      expect(page).to have_selector("[data-testid='recipe-comments-count']", text: "1")
    end

    it "Posts a comment and returns to the recipe" do
      recipe = published_recipe
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Tasty" } }

      expect(page).to have_current_path(recipe_path(recipe))
      expect(recipe.reload.comments.sole.body.to_plain_text).to eq("Tasty")
    end

    it "Shows threads newest first, with replies under them" do
      recipe = published_recipe
      older = create(:comment, commentable: recipe, user: charlie, body: "First comment", created_at: 2.days.ago)
      create(:comment, commentable: recipe, user: charlie, body: "Second comment", created_at: 1.day.ago)
      create(:comment, commentable: recipe, user: uno, body: "A reply", parent: older)
      sign_in_as(uno)
      visit recipe_path(recipe)

      expect(page).to have_selector("[data-testid='comments-count']", text: "3 comments in 2 threads")
      expect(page.text.index("Second comment")).to be < page.text.index("First comment")
      expect(page).to have_css(".comment--reply", text: "A reply")
    end

    it "Replies to a thread" do
      recipe = published_recipe
      thread = create(:comment, commentable: recipe, user: charlie, body: "Original")
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Agreed", parent_id: thread.id } }

      expect(thread.reload.replies.sole.body.to_plain_text).to eq("Agreed")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows the thread but no comment box to 'Gary Guest'" do
      recipe = published_recipe
      create(:comment, commentable: recipe, user: charlie, body: "A comment")
      visit recipe_path(recipe)

      expect(page).to have_selector("[data-testid='comment-body']", text: "A comment")
      expect(page).to have_no_css("[data-testid='comment-body-field']")
      expect(page).to have_no_button("Reply")
    end

    it "Redirects 'Gary Guest' to the 'Sign in' page on a direct comment request" do
      recipe = published_recipe
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Hi" } }
      expect(page).to have_current_path(new_session_path)
    end

    it "Denies commenting on a recipe the user cannot read" do
      recipe = create(:recipe, :published, :restricted, user: charlie)
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Hi" } }

      expect(page).to have_current_path(cookbook_path)
      expect(page).to have_content("Not authorised")
      expect(recipe.reload.comments).to be_empty
    end

    it "Denies commenting on someone else's draft" do
      recipe = create(:recipe, :unrestricted, user: charlie)
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Hi" } }
      expect(recipe.reload.comments).to be_empty
    end

    it "Rejects a blank comment" do
      recipe = published_recipe
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "" } }

      expect(page).to have_current_path(recipe_path(recipe))
      expect(recipe.reload.comments).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets the owner comment on their own draft" do
      recipe = create(:recipe, user: charlie)
      sign_in_as(charlie)
      visit recipe_path(recipe)
      expect(page).to have_css("[data-testid='comment-body-field']", visible: :all)

      page.driver.submit :post, recipe_comments_path(recipe), { comment: { body: "Needs more salt" } }
      expect(recipe.reload.comments.count).to eq(1)
    end

    it "Lets the commenter delete their own comment, returning to the recipe" do
      recipe = published_recipe
      comment = create(:comment, commentable: recipe, user: uno, body: "Oops")
      sign_in_as(uno)
      visit recipe_path(recipe)
      find("[data-testid='delete-comment-#{comment.id}']").click

      expect(page).to have_current_path(recipe_path(recipe))
      expect(recipe.reload.comments).to be_empty
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Removes a recipe's comments when it is purged" do
      recipe = published_recipe(deleted_at: 31.days.ago)
      create(:comment, commentable: recipe, user: uno)
      expect { PurgeDeletedRecipesJob.perform_now }.to change(Comment, :count).by(-1)
    end

    it "Returns 404 for a comment on a recipe that doesn't exist" do
      sign_in_as(uno)
      page.driver.submit :post, recipe_comments_path("no-such-recipe"), { comment: { body: "Hi" } }
      expect(page.status_code).to eq(404)
    end
  end
end
