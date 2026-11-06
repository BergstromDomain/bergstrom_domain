# spec/features/dossier/skill_categories_spec.rb
require "rails_helper"

RSpec.describe "Dossier Skill Categories", type: :feature do
  let(:factory)     { :dossier_skill_category }
  let(:model)       { Dossier::SkillCategory }
  let(:singular)    { "Skill Category" }
  let(:plural)      { "Skill Categories" }
  let(:index_path)  { dossier_skill_categories_path }
  let(:new_path)    { new_dossier_skill_category_path }
  let(:record_name) { "Test Tools" }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)
  def fill_valid_form = fill_name(record_name)

  it_behaves_like "Dossier reference data pages", content_creators_can_create: false

  describe "Skills in a Skill Category" do
    let(:databases) { create(:dossier_skill_category, name: "Databases") }

    def table = find("[data-testid='category-skills']")
    def rows  = table.all("[data-testid='category-skill-row']")

    # 1) Happy Path ─────────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "Lists the category's Skills A–Z with aliases, versions and your years" do
        user = create(:user, :content_creator)
        oracle = create(:dossier_skill, name: "Oracle", skill_category: databases)
        create(:dossier_skill, name: "Oracle 12c", skill_category: databases, parent: oracle)
        create(:dossier_skill, name: "mysql", skill_category: databases, aliases_text: "MySQL Server")
        create(:dossier_skill, name: "Jira", skill_category: create(:dossier_skill_category, name: "Test Tools"))
        create(:dossier_assignment, engagement: create(:dossier_engagement, user: user, start_month: "2015-01", end_month: "2016-12"),
                                    start_month: "2015-01", end_month: "2016-12", other_tools_na: false, other_tools_text: "Oracle 12c")
        sign_in_as(user)
        visit dossier_skill_category_path(databases)

        expect(table).to have_selector("h2", text: "Skills (3)")
        expect(rows.map { |row| row.find("td", match: :first).text }).to eq([ "mysql", "Oracle", "Oracle 12c" ])
        expect(rows[0]).to have_text("MySQL Server")
        expect(rows[1]).to have_link("Oracle", href: dossier_skill_path(oracle))
        expect(rows[1]).to have_text("2+ years")
        expect(rows[2]).to have_link("Oracle", href: dossier_skill_path(oracle))
        expect(rows[2]).to have_text("Dec 2016")
        expect(table).not_to have_text("Jira")
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "Shows no years to a visitor" do
        create(:dossier_skill, name: "Oracle", skill_category: databases)
        visit dossier_skill_category_path(databases)

        expect(rows.size).to eq(1)
        expect(table).not_to have_selector("th", text: "Your Years")
      end
    end

    # 3) Alternative Paths ───────────────────────────────────────────────────────
    describe "Alternative Paths" do
      it "Shows — for a Skill you haven't used" do
        create(:dossier_skill, name: "Oracle", skill_category: databases)
        sign_in_as(create(:user, :content_creator))
        visit dossier_skill_category_path(databases)

        expect(rows.first.all("td").map(&:text)).to eq([ "Oracle", "—", "—", "—", "—" ])
      end
    end

    # 4) Edge Cases ─────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "Says so when the category has no Skills" do
        visit dossier_skill_category_path(databases)

        expect(table).to have_selector("[data-testid='category-skills-empty']", text: "No Skills in Databases yet.")
      end
    end
  end
end
