# spec/features/dossier/assignment_order_spec.rb
require "rails_helper"

# An Engagement's Assignments in a hand-made order: Up/Down on the Engagement
# page, the same order on the Timeline (without buttons), and bench time
# listed after the Assignments.
RSpec.describe "Dossier Assignment order", type: :feature do
  let(:charlie) { create(:user, :content_creator) }
  let(:chris)   { create(:user, :content_creator) }

  let(:qbcc) { create(:dossier_organisation, name: "Queensland Building and Construction Commission", abbreviation: "QBCC") }
  let(:engagement) { create(:dossier_engagement, user: charlie, start_month: "2024-09", end_month: "2026-12") }

  def assignment(project, start_month, end_month)
    create(:dossier_assignment, engagement: engagement, client: qbcc, project: project,
                                start_month: start_month, end_month: end_month)
  end

  def rows = all("[data-testid='assignment-row'] .data-table__name-link").map(&:text)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Moves Portfolio Test Manager above FSIP, keeping the scroll, and the Timeline follows", js: true do
      assignment("Digital Licencing", "2024-09", "2025-06")
      %w[One Two Three Four Five].each_with_index { |name, i| assignment("Project #{name}", format("2025-%02d", i + 7), format("2025-%02d", i + 7)) }
      assignment("Portfolio Test Manager", "2026-07", "2026-11")
      assignment("FSIP", "2026-05", "2026-12")
      sign_in_and_settle(charlie)
      visit dossier_engagement_path(engagement)
      expect(rows.first(2)).to eq([ "QBCC - FSIP", "QBCC - Portfolio Test Manager" ])

      scroll_top = "document.querySelector('.site-main').scrollTop"
      up = all("[data-testid='assignment-move-up']", minimum: 2)[1]
      page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", up)
      before = page.evaluate_script(scroll_top)
      expect(before).to be > 0
      up.click

      expect(page).to have_css("[data-testid='assignment-row']:first-child", text: "Portfolio Test Manager")
      expect(page.evaluate_script(scroll_top)).to be_within(5).of(before)

      visit dossier_engagements_path
      expect(rows.first(2)).to eq([ "QBCC - Portfolio Test Manager", "QBCC - FSIP" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows Chris no Up/Down on Charlie's Unrestricted Engagement" do
      assignment("FSIP", "2026-05", "2026-12")
      engagement.update!(classification: "unrestricted")
      sign_in_as(chris)
      visit dossier_engagement_path(engagement)

      expect(page).to have_selector("[data-testid='assignment-row']")
      expect(page).not_to have_selector("[data-testid='assignment-move-up']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Shows no Up/Down on the Timeline" do
      assignment("FSIP", "2026-05", "2026-12")
      sign_in_as(charlie)
      visit dossier_engagements_path

      expect(page).to have_selector("[data-testid='assignment-row']")
      expect(page).not_to have_selector("[data-testid='assignment-move-up']")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Lists bench time after the Assignments, newest first, and disables Up on the top row and Down on the bottom" do
      assignment("Digital Licencing", "2024-09", "2025-01")
      assignment("FSIP", "2025-06", "2025-12")
      sign_in_as(charlie)
      visit dossier_engagement_path(engagement)

      kinds = all(".dossier-assignment-list > li").map { |row| row["data-testid"] }
      expect(kinds).to eq(%w[assignment-row assignment-row timeline-bench timeline-bench])
      expect(all("[data-testid='timeline-bench'] .dossier-assignment-row__dates").map(&:text))
        .to eq([ "Jan 2026 – Dec 2026", "Feb 2025 – May 2025" ])
      expect(all("[data-testid='assignment-move-up']").first).to be_disabled
      expect(all("[data-testid='assignment-move-down']").last).to be_disabled
    end
  end
end
