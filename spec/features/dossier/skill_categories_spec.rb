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

  describe "Sub-categories" do
    let(:adam)      { create(:user, :admin) }
    let(:protocols) { create(:dossier_skill_category, name: "Protocols & Standards") }

    def table = find("[data-testid='category-skills']")
    def rows  = table.all("[data-testid='category-skill-row']")

    # 1) Happy Path ─────────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "Lets Adam create a sub-category by choosing its Parent" do
        protocols
        sign_in_as(adam)
        visit new_dossier_skill_category_path
        fill_in "Name", with: "VoIP"
        select "Protocols & Standards", from: "Parent"
        click_button "Create Skill Category"

        expect(page).to have_css("[data-testid='flash-success']", text: "Protocols & Standards › VoIP has been successfully created")
        expect(page).to have_selector("[data-testid='detail-part-of'] a[href='#{dossier_skill_category_path(protocols)}']",
                                      text: "Protocols & Standards")
      end

      it "Lists a top-level category's sub-categories and all their Skills" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        create(:dossier_skill_category, name: "Web", parent: protocols)
        create(:dossier_skill, name: "SIP", skill_category: voip)
        create(:dossier_skill, name: "TCP/IP", skill_category: protocols)
        visit dossier_skill_category_path(protocols)

        panel = find("[data-testid='category-subcategories']")
        expect(panel.all("[data-testid='category-subcategory-row']").map { |row| row.all("td").map(&:text) })
          .to eq([ [ "VoIP", "1" ], [ "Web", "0" ] ])
        expect(table).to have_selector("h2", text: "Skills (2)")
        expect(rows.map { |row| row.all("td").first(2).map(&:text) }).to eq([ [ "SIP", "VoIP" ], [ "TCP/IP", "—" ] ])
      end

      it "Lists each sub-category right after its parent on the index" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        create(:dossier_skill_category, name: "AI Tools")
        create(:dossier_skill_category, name: "Testing")
        visit dossier_skill_categories_path

        expect(all("[data-testid='reference-data-name']").map(&:text))
          .to eq([ "AI Tools", "Protocols & Standards", "Protocols & Standards › VoIP", "Testing" ])
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "Won't delete a category that has sub-categories" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        sign_in_as(adam)
        visit dossier_skill_category_path(protocols)
        click_button "Delete Skill Category"

        expect(page).to have_content("Cannot delete record because dependent sub-categories exist")
        expect(Dossier::SkillCategory.exists?(protocols.id)).to be(true)
      end

      it "Shows a top-level category no Part Of row and a sub-category no sub-categories panel" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        visit dossier_skill_category_path(voip)

        expect(page).to have_selector("h1.page-title", text: "Protocols & Standards › VoIP")
        expect(page).not_to have_selector("[data-testid='category-subcategories']")
        visit dossier_skill_category_path(protocols)
        expect(page).to have_selector("[data-testid='detail-part-of']", text: "—")
      end
    end

    # 3) Alternative Path ───────────────────────────────────────────────────────
    describe "Alternative Path" do
      it "Promotes a sub-category to top-level when Adam clears its Parent" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        sign_in_as(adam)
        visit edit_dossier_skill_category_path(voip)
        select "None (top-level)", from: "Parent"
        click_button "Update Skill Category"

        expect(page).to have_selector("h1.page-title", text: /\AVoIP\z/)
        expect(voip.reload.parent).to be_nil
      end
    end

    # 4) Edge Cases ─────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "Offers only other top-level categories as a Parent" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        create(:dossier_skill_category, name: "Testing")
        sign_in_as(adam)
        visit edit_dossier_skill_category_path(protocols)

        expect(page).to have_select("Parent", options: [ "None (top-level)", "Testing" ])
      end

      it "Says so when neither the category nor its sub-categories have Skills" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        visit dossier_skill_category_path(protocols)

        expect(page).to have_selector("[data-testid='category-subcategory-row']", text: "VoIP")
        expect(table).to have_selector("[data-testid='category-skills-empty']", text: "No Skills in Protocols & Standards yet.")
      end
    end
  end
end
