# spec/views/blog_posts/_likes_breakdown.html.erb_spec.rb
require "rails_helper"

RSpec.describe "blog_posts/_likes_breakdown", type: :view do
  let(:owner) { create(:user) }

  def render_breakdown(post)
    render partial: "blog_posts/likes_breakdown", locals: { blog_post: post }
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders the total score, combined face, and total reaction count" do
      post = create(:blog_post, user: owner)
      post.likes.create!(user: create(:user), face: "grinning")
      post.likes.create!(user: create(:user), face: "grinning")

      render_breakdown(post)

      expect(rendered).to have_css("[data-testid='likes-breakdown-score']", text: "5.0")
      expect(rendered).to have_css("[data-testid='likes-breakdown-total']", text: "2 reactions")
      expect(rendered).to have_css(".likes-breakdown__combined-face.like-face--grinning")
    end

    it "renders a row per face with its own count and proportional bar width" do
      post = create(:blog_post, user: owner)
      post.likes.create!(user: create(:user), face: "grinning")
      post.likes.create!(user: create(:user), face: "angry")

      render_breakdown(post)

      expect(rendered).to have_css("[data-testid='likes-breakdown-row-grinning']", text: "1")
      expect(rendered).to have_css(
        "[data-testid='likes-breakdown-row-grinning'] .likes-breakdown__bar-fill.like-face-bg--grinning[style*='width: 50.0%']"
      )
      expect(rendered).to have_css(
        "[data-testid='likes-breakdown-row-angry'] .likes-breakdown__bar-fill.like-face-bg--angry[style*='width: 50.0%']"
      )
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "renders exactly one heading and exactly five rows, never more or fewer" do
      post = create(:blog_post, user: owner)
      post.likes.create!(user: create(:user), face: "grinning")

      render_breakdown(post)

      expect(rendered.scan("<h2").size).to eq(1)
      expect(rendered).to have_css(".likes-breakdown__row", count: 5)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "shows the other four faces at zero when every reactor picked the same face" do
      post = create(:blog_post, user: owner)
      create_list(:user, 3).each { |user| post.likes.create!(user: user, face: "neutral") }

      render_breakdown(post)

      expect(rendered).to have_css("[data-testid='likes-breakdown-row-neutral']", text: "3")
      %w[grinning slightly_smiling slightly_frowning angry].each do |face|
        expect(rendered).to have_css("[data-testid='likes-breakdown-row-#{face}']", text: "0")
        expect(rendered).to have_css(
          "[data-testid='likes-breakdown-row-#{face}'] .likes-breakdown__bar-fill[style*='width: 0.0%']"
        )
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "rounds an uneven split to one decimal place rather than a repeating decimal" do
      post = create(:blog_post, user: owner)
      post.likes.create!(user: create(:user), face: "grinning")
      post.likes.create!(user: create(:user), face: "angry")
      post.likes.create!(user: create(:user), face: "neutral")

      render_breakdown(post)

      # 1/3 = 33.333...% — must render as "33.3%", not the raw float.
      expect(rendered).to have_css(
        "[data-testid='likes-breakdown-row-grinning'] .likes-breakdown__bar-fill[style*='width: 33.3%']"
      )
    end
  end
end
