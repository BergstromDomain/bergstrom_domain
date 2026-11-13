# spec/features/layouts/page_header_spec.rb
require "rails_helper"

# Page headers line up with the content on the left, in every app; only the
# sign-in and sign-up cards keep a centred title.
RSpec.describe "Page header alignment", type: :feature do
  let(:charlie) { create(:user, :content_creator) }

  def style(selector, property)
    page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
  end

  def title_left_offset
    page.evaluate_script(<<~JS)
      (() => {
        const header = document.querySelector('.page-header');
        const title = header.querySelector('.page-title');
        return title.getBoundingClientRect().left - header.getBoundingClientRect().left;
      })()
    JS
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Starts the title at the header's left edge on a page that used to centre it", js: true do
      visit events_path

      expect(page).to have_css(".page-header__top--centered .page-title", text: "Events")
      expect(style(".page-header__top--centered", "justifyContent")).not_to eq("center")
      expect(title_left_offset).to be < 2
    end

    it "Left-aligns a centred subtitle", js: true do
      sign_in_and_settle(charlie)
      visit dossier_engagements_path

      expect(style(".page-header__subtitle--centered", "textAlign")).to eq("start").or eq("left")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Keeps the sign-in card's title centred", js: true do
      visit new_session_path

      expect(style(".auth-layout .page-header", "textAlign")).to eq("center")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Left-aligns a header that uses the page-level centred modifier", js: true do
      visit events_path
      page.execute_script("document.querySelector('.page-header').classList.add('page-header--centered')")

      expect(style(".page-header--centered", "textAlign")).to eq("start").or eq("left")
      expect(style(".page-header--centered .page-header__top", "justifyContent")).not_to eq("center")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps the sign-up card's title centred", js: true do
      visit sign_up_path

      expect(style(".auth-layout .page-header", "textAlign")).to eq("center")
    end
  end
end
