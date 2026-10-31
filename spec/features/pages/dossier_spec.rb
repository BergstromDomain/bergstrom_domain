# spec/features/pages/dossier_spec.rb
require "rails_helper"

RSpec.describe "Dossier", type: :feature do
  let(:uno)     { create(:user) }
  let(:charlie) { create(:user, :content_creator) }
  let(:adam)    { create(:user, :admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { visit dossier_path }

    it "Shows the Dossier heading and subtitle" do
      expect(page).to have_selector("h1.page-title", text: "Dossier")
      expect(page).to have_selector(".page-header__subtitle", text: "Your whole career in one place, ready for any CV.")
    end

    it "Renders via the shared app landing template with the Dossier hero image" do
      expect(page).to have_selector("[data-testid='app-landing']")
      expect(page).to have_selector("img.app-landing__hero-image[alt='Dossier preview'][src*='dossier-hero']")
    end

    it "Shows the About section with three titled cards" do
      expect(page).to have_selector("[data-testid='app-landing-about-1'] h2", text: "Record It Once")
      expect(page).to have_selector("[data-testid='app-landing-about-2'] h2", text: "Tailor Without Losing Anything")
      expect(page).to have_selector("[data-testid='app-landing-about-3'] h2", text: "Private By Default")
    end

    it "Shows the left nav, with its own link back to this page and a User Guide link" do
      within("[data-testid='left-nav']") do
        expect(page).to have_selector("[data-testid='left-nav-dossier-h3']", text: "Dossier")
        expect(page).to have_link("Dossier", href: dossier_path)
        expect(page).to have_link("User Guide", href: user_guide_path)
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows no other app's left nav links" do
      visit dossier_path
      within("[data-testid='left-nav']") do
        expect(page).not_to have_link("Chronicle", href: chronicle_path)
        expect(page).not_to have_link("Cookbook", href: cookbook_path)
        expect(page).not_to have_link("Occasions", href: event_tracker_path)
      end
    end

    it "Shows an App User the views but no Actions section" do
      sign_in_as(uno)
      visit dossier_path
      within("[data-testid='left-nav']") do
        expect(page).to have_link("Dossier", href: dossier_path)
        expect(page).not_to have_selector("[data-testid='left-nav-actions-h2']")
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Is reachable from the 'Apps' menu" do
      visit root_path
      click_button "Apps"
      click_link "Dossier"
      expect(page).to have_current_path(dossier_path)
    end

    it "Groups an Admin's Actions into New and Reference Data" do
      sign_in_as(adam)
      visit dossier_path
      within("[data-testid='left-nav']") do
        links = all(".left-nav-h3, .left-nav-link span").map(&:text)
        new_at = links.index("New")
        reference_at = links.rindex("Reference Data")
        expect(links[new_at + 1..new_at + 4]).to eq([ "Create An Engagement", "Create An Assignment", "Add An Organisation", "Add A Skill" ])
        expect(links[reference_at + 1..reference_at + 5]).to eq(
          [ "Add An Industry", "Add A Role", "Add A Location", "Add An Employment Type", "Add A Skill Category" ]
        )
      end
    end

    it "Shows a Content Creator the New Actions but no Reference Data Actions" do
      sign_in_as(charlie)
      visit dossier_path
      within("[data-testid='left-nav']") do
        expect(page).to have_selector("[data-testid='left-nav-new-h3']")
        expect(page).to have_link("Add A Skill")
        expect(page).not_to have_selector("[data-testid='left-nav-actions-reference-data-h3']")
        expect(page).not_to have_link("Add An Industry")
      end
    end

    it "Is reachable by a signed-in Content Creator" do
      sign_in_as(charlie)
      visit dossier_path
      expect(page).to have_selector("h1.page-title", text: "Dossier")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Is public: a guest sees it without signing in" do
      visit dossier_path
      expect(page).to have_current_path(dossier_path)
      expect(page).to have_link("Sign In", href: new_session_path)
    end
  end
end
