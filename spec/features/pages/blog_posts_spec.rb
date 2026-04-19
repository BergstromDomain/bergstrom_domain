# spec/features/pages/blog_posts_spec.rb
require "rails_helper"

RSpec.describe "Blog posts stub page", type: :feature do
  context "when unauthenticated" do
    it "renders the under construction page" do
      visit blog_posts_path
      expect(page).to have_css("h1", text: "Blog Posts")
      expect(page).to have_text("Under construction")
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "renders the under construction page" do
      visit blog_posts_path
      expect(page).to have_css("h1", text: "Blog Posts")
      expect(page).to have_text("Under construction")
    end
  end
end
