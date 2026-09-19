# spec/features/blog_posts/likes_breakdown_popup_spec.rb
require "rails_helper"

RSpec.describe "Likes Breakdown Popup", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  def published_post_with_reactions
    post = create(:blog_post, :unrestricted, :published, user: owner)
    post.likes.create!(user: create(:user), face: "grinning")
    post.likes.create!(user: create(:user), face: "grinning")
    post.likes.create!(user: create(:user), face: "angry")
    post
  end

  # See spec/features/shared/confirm_dialog_spec.rb for provenance of
  # js_click and the visible: :all / [open] assertion style — the same
  # native-<dialog>-via-showModal() quirks apply to this popup, since
  # popup_controller.js follows the same Esc/backdrop/focus-return
  # conventions as confirm_dialog_controller.js.
  def open_breakdown_popup(post)
    visit blog_post_path(post)
    js_click("blog-post-likes-count")
    find("[data-testid='likes-breakdown-popup'][open]", visible: :all, wait: 10)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Opens the breakdown popup with the score, combined face, total, and a row per face", js: true do
      post = published_post_with_reactions

      dialog = open_breakdown_popup(post)

      expect(dialog).to have_css("[data-testid='likes-breakdown-score']", text: "3.7")
      # (5 + 5 + 1) / 3 = 3.667, rounds to 4 points -> slightly_smiling.
      expect(dialog).to have_css(".likes-breakdown__combined-face.like-face--slightly_smiling")
      expect(dialog).to have_css("[data-testid='likes-breakdown-total']", text: "3 reactions")
      expect(dialog).to have_css("[data-testid='likes-breakdown-row-grinning']", text: "2")
      expect(dialog).to have_css("[data-testid='likes-breakdown-row-angry']", text: "1")
      expect(dialog).to have_css("[data-testid='likes-breakdown-row-neutral']", text: "0")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not render a clickable trigger when nobody has reacted yet", js: true do
      post = create(:blog_post, :unrestricted, :published, user: owner)

      visit blog_post_path(post)

      expect(page).to have_no_css("button[data-testid='blog-post-likes-count']")
      expect(page).to have_css("p[data-testid='blog-post-likes-count']", text: "No reactions yet")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets a guest open and view the breakdown, same as a signed-in user", js: true do
      post = published_post_with_reactions

      dialog = open_breakdown_popup(post)

      expect(dialog).to have_css("[data-testid='likes-breakdown-total']", text: "3 reactions")
    end

    it "Closes when the close button is clicked", js: true do
      post = published_post_with_reactions
      open_breakdown_popup(post)

      js_click("likes-breakdown-popup-close")

      expect(page).to have_no_css("[data-testid='likes-breakdown-popup'][open]", visible: :all)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Closes on Escape", js: true do
      post = published_post_with_reactions
      open_breakdown_popup(post)

      page.driver.browser.action.send_keys(:escape).perform

      expect(page).to have_no_css("[data-testid='likes-breakdown-popup'][open]", visible: :all)
    end

    it "Closes when the dimmed backdrop is clicked", js: true do
      post = published_post_with_reactions
      open_breakdown_popup(post)

      # Selenium's click(x:, y:) offsets are relative to the element's
      # center (W3C WebDriver) — the dialog fills the viewport, so an
      # offset well outside the centered card's half-width lands on the
      # backdrop, same technique as the Confirm Dialog spec.
      find("[data-testid='likes-breakdown-popup'][open]", visible: :all, wait: 10).click(x: -300, y: 0)

      expect(page).to have_no_css("[data-testid='likes-breakdown-popup'][open]", visible: :all)
    end

    it "Returns focus to the trigger after closing", js: true do
      post = published_post_with_reactions
      open_breakdown_popup(post)

      js_click("likes-breakdown-popup-close")

      expect(page).to have_no_css("[data-testid='likes-breakdown-popup'][open]", visible: :all)
      expect(page.evaluate_script("document.activeElement.dataset.testid")).to eq("blog-post-likes-count")
    end
  end
end
