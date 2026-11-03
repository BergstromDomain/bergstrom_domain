# spec/features/dossier/skill_merge_spec.rb
require "rails_helper"

RSpec.describe "Dossier Merge Skills", type: :feature do
  let(:adam)    { create(:user, :admin) }
  let(:charlie) { create(:user, :content_creator) }

  let!(:excel)    { create(:dossier_skill, name: "Excel") }
  let!(:ms_excel) { create(:dossier_skill, name: "MS Excel", aliases_text: "Microsoft Excel") }
  let!(:assignment) do
    create(:dossier_assignment, engagement: create(:dossier_engagement, user: charlie),
                                other_tools_na: false, other_tools_text: "MS Excel")
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lets an Admin merge a Skill into another from its page, with a toast" do
      sign_in_as(adam)
      visit dossier_skill_path(ms_excel)
      click_link "Merge Into…"

      expect(page).to have_selector("h1.page-title", text: "Merge MS Excel")
      select "Excel", from: "Merge Into"
      click_button "Merge Skill"

      expect(page).to have_current_path(dossier_skill_path(excel))
      expect(page).to have_css("[data-testid='flash-success']", text: "MS Excel has been successfully merged into Excel")
      expect(page).to have_selector("[data-testid='detail-aliases']", text: "MS Excel, Microsoft Excel")
      expect(assignment.reload.other_tools_text).to eq("Excel")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Gives a Content Creator no Merge Into… and keeps them off the merge page" do
      sign_in_as(charlie)
      visit dossier_skill_path(ms_excel)
      expect(page).not_to have_link("Merge Into…")

      visit merge_dossier_skill_path(ms_excel)
      expect(page).to have_current_path(dossier_skill_path(ms_excel))
      expect(page).to have_content("Not authorised.")
    end

    it "Asks for the Skill to keep when none is chosen" do
      sign_in_as(adam)
      visit merge_dossier_skill_path(ms_excel)
      click_button "Merge Skill"

      expect(page).to have_content("Choose the Skill to keep.")
      expect(Dossier::Skill.exists?(ms_excel.id)).to be(true)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Goes back to the Skill on Cancel" do
      sign_in_as(adam)
      visit merge_dossier_skill_path(ms_excel)
      click_link "Cancel"
      expect(page).to have_current_path(dossier_skill_path(ms_excel))
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Doesn't offer the Skill itself as the one to keep" do
      sign_in_as(adam)
      visit merge_dossier_skill_path(ms_excel)
      expect(page).not_to have_select("Merge Into", with_options: [ "MS Excel" ])
    end
  end
end
