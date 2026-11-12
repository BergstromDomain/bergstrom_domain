# spec/features/dossier/cv_variant_selection_spec.rb
require "rails_helper"

RSpec.describe "Dossier CV Variant Edit Selection", type: :feature do
  include ActiveSupport::Testing::TimeHelpers
  include ActionView::RecordIdentifier

  let(:charlie) { create(:user, :content_creator) }
  let(:variant) { create(:dossier_cv_variant, user: charlie, name: "Acme") }
  let!(:jira) { create(:dossier_skill, name: "Jira") }
  let!(:engagement) do
    create(:dossier_engagement, user: charlie, position_title: "Test Consultant",
                                employer: create(:dossier_organisation, name: "Bridge"), start_month: "2019-03", end_month: "2022-06")
  end
  let!(:assignment) do
    create(:dossier_assignment, engagement: engagement, client: create(:dossier_organisation, name: "Westpac"),
                                test_tools_na: false, test_tools_text: "Jira")
  end
  let!(:triage)  { create(:dossier_achievement, assignment: assignment, text: "Ran daily defect triage", importance: 4) }
  let!(:minutes) { create(:dossier_achievement, assignment: assignment, text: "Took meeting minutes", importance: 1) }
  let!(:istqb)   { create(:dossier_credential, :certification, user: charlie, title: "ISTQB Foundation") }

  def box(record) = find("##{dom_id(record, :selection)}")

  around { |example| travel_to(Date.new(2026, 11, 6)) { example.run } }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the default selection, then saves ticks and unticks" do
      sign_in_as(charlie)
      visit dossier_cv_variant_path(variant)
      click_link "Edit Selection"

      expect(page).to have_selector("h1.page-title", text: "Edit Selection")
      expect(box(engagement)).to be_checked
      expect(box(assignment)).to be_checked
      expect(box(triage)).to be_checked
      expect(box(minutes)).not_to be_checked
      expect(page).to have_selector("[data-testid='selection-achievement']", text: "Importance 1")
      expect(box(jira)).to be_checked
      expect(box(istqb)).to be_checked

      box(minutes).check
      box(istqb).uncheck
      click_button "Save Selection"

      expect(page).to have_current_path(dossier_cv_variant_path(variant))
      expect(page).to have_css("[data-testid='flash-success']", text: "Acme's selection has been saved")
      expect(variant.items.map { |i| [ i.item, i.included ] }).to contain_exactly([ minutes, true ], [ istqb, false ])
    end

    it "Resets to the defaults" do
      variant.items.create!(item: istqb, included: false)
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)

      expect(box(istqb)).not_to be_checked
      expect(page).to have_selector("[data-testid='selection-credential']", text: "Your choice")
      click_button "Reset To Defaults"

      expect(page).to have_css("[data-testid='flash-success']", text: "Acme is back to the default selection")
      expect(variant.items.reload).to be_empty
    end

    it "Ticks a Contribution, which then counts in What's Included and is on the CV" do
      talk = create(:dossier_contribution, user: charlie, title: "Statistical Methods",
                                           event: create(:dossier_organisation, name: "All Things Testing"))
      create(:dossier_profile, user: charlie)
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)

      within("[data-testid='selection-contributions']") do
        expect(page).to have_selector("h2", text: "Presentations & Community")
        expect(find("[data-testid='selection-contribution']")).to have_text("Talk")
      end
      expect(box(talk)).not_to be_checked
      box(talk).check
      click_button "Save Selection"

      expect(find("[data-testid='cv-variant-included']")).to have_text("1 Contribution")
      expect(Dossier::CvDocument.new(charlie, variant: variant).contributions.map(&:title)).to eq([ "Statistical Methods" ])
      visit selection_dossier_cv_variant_path(variant)
      expect(find("[data-testid='selection-contribution']")).to have_text("Your choice")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Turns away another Content Creator" do
      sign_in_as(create(:user, :content_creator))
      visit selection_dossier_cv_variant_path(variant)

      expect(page).to have_current_path(dossier_cv_variants_path)
    end

    it "Ignores records that aren't the user's own" do
      theirs = create(:dossier_engagement, position_title: "Someone Else's Job")
      sign_in_as(charlie)
      page.driver.submit :patch, selection_dossier_cv_variant_path(variant),
                         selection: { engagement: { theirs.id.to_s => "0", engagement.id.to_s => "0" } }

      expect(variant.items.map(&:item)).to eq([ engagement ])
    end

    it "Ignores another user's Contribution" do
      theirs = create(:dossier_contribution, title: "Someone Else's Talk")
      sign_in_as(charlie)
      page.driver.submit :patch, selection_dossier_cv_variant_path(variant), selection: { contribution: { theirs.id.to_s => "1" } }

      expect(variant.items.reload).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Marks Personal Projects and older Engagements, which start unticked or condensed" do
      create(:dossier_engagement, :personal, user: charlie, position_title: "Home Lab")
      old = create(:dossier_engagement, user: charlie, position_title: "Tester", start_month: "2010-01", end_month: "2015-12")
      old_assignment = create(:dossier_assignment, engagement: old)
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)

      expect(page).to have_selector("[data-testid='selection-engagement']", text: "Home Lab")
      expect(page).to have_selector("[data-testid='selection-engagement']", text: "Personal Project")
      expect(page).to have_selector("[data-testid='selection-engagement']", text: "Condensed")
      expect(box(old)).to be_checked
      expect(box(old_assignment)).not_to be_checked
    end

    it "Groups Skills under 'Parent › Sub' headings, each sub-category after its parent" do
      protocols = create(:dossier_skill_category, name: "Protocols & Standards")
      create(:dossier_skill, name: "SIP", skill_category: create(:dossier_skill_category, name: "VoIP", parent: protocols))
      create(:dossier_skill, name: "TCP/IP", skill_category: protocols)
      assignment.update!(other_tools_na: false, other_tools_text: "SIP, TCP/IP")
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)

      headings = find("[data-testid='selection-skills']").all("h3").map(&:text)
      expect(headings.each_cons(2)).to include([ "Protocols & Standards", "Protocols & Standards › VoIP" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps no row for a box left at its default" do
      variant.items.create!(item: triage, included: false)
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)
      box(triage).check
      click_button "Save Selection"

      expect(variant.items.reload).to be_empty
    end

    it "Unticks a ticked Contribution back to the default, leaving no row and no Your choice" do
      talk = create(:dossier_contribution, user: charlie)
      variant.items.create!(item: talk, included: true)
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)
      box(talk).uncheck
      click_button "Save Selection"

      expect(variant.items.reload).to be_empty
      visit selection_dossier_cv_variant_path(variant)
      expect(find("[data-testid='selection-contribution']")).to have_no_text("Your choice")
    end

    it "Says No Contributions yet when there are none" do
      sign_in_as(charlie)
      visit selection_dossier_cv_variant_path(variant)

      expect(find("[data-testid='selection-contributions']")).to have_text("No Contributions yet.")
    end
  end
end
