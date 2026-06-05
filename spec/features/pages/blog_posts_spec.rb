# spec/features/pages/blog_posts_spec.rb
require "rails_helper"

RSpec.describe "Blog Posts page", type: :feature do
  context "When 'Gary Guest' visits the 'Blog Posts' page" do
    it "Renders the 'Under construction' page" do
      visit blog_posts_path
      expect(page).to have_selector("h1", text: "Blog Posts")
      expect(page).to have_text("Under construction")
    end
  end

  context "When 'Uno User' is signed in and visits the 'Blog Posts' page" do
    let(:uno) { create(:user) }

    before do
      sign_in_as(uno)
    end

    it "Renders the 'Under construction' page" do
      visit blog_posts_path
      expect(page).to have_selector("h1", text: "Blog Posts")
      expect(page).to have_text("Under construction")
    end
  end
end
