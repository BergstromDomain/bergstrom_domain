# spec/features/dossier/organisations_spec.rb
require "rails_helper"

RSpec.describe "Dossier Organisations", type: :feature do
  let(:factory)     { :dossier_organisation }
  let(:model)       { Dossier::Organisation }
  let(:singular)    { "Organisation" }
  let(:plural)      { "Organisations" }
  let(:index_path)  { dossier_organisations_path }
  let(:new_path)    { new_dossier_organisation_path }
  let(:record_name) { "Northwind Transport Authority" }
  let!(:transport)  { create(:dossier_industry, name: "Transport") }

  def sortable_attributes(text) = { name: text }
  def fill_name(text) = fill_in("Name", with: text)

  def fill_valid_form
    fill_name(record_name)
    fill_in "Abbreviation", with: "NTA"
    select "Transport", from: "Industry"
    fill_in "Website", with: "https://northwind.example"
  end

  it_behaves_like "Dossier reference data pages", content_creators_can_create: true

  describe "Happy Path (Organisation)" do
    it "Shows the abbreviation, industry and website" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      click_button "Create Organisation"

      expect(page).to have_selector("[data-testid='detail-abbreviation']", text: "NTA")
      expect(page).to have_selector("[data-testid='detail-industry']", text: "Transport")
      expect(page).to have_link("https://northwind.example", href: "https://northwind.example")
    end

    it "Lists your own Credentials the Organisation issued, of any type, not anyone else's" do
      charlie = create(:user, :content_creator)
      ni = create(:dossier_organisation, name: "National Instruments")
      create(:dossier_credential, user: charlie, provider: ni, title: "LabVIEW Core 1", skills_text: "LabVIEW")
      create(:dossier_credential, :certification, user: charlie, provider: ni, title: "Certified LabVIEW Developer")
      create(:dossier_credential, provider: ni, title: "Someone Else's Course")
      sign_in_as(charlie)
      visit dossier_organisation_path(ni)

      within("[data-testid='organisation-credentials']") do
        expect(page).to have_selector("h2", text: "Your Credentials")
        expect(page).to have_link("LabVIEW Core 1")
        expect(page).to have_link("Certified LabVIEW Developer")
        expect(page).not_to have_content("Someone Else's Course")
      end
    end
  end

  describe "Happy Path (Organisation as Vendor or Customer)" do
    it "Lists your Assignments where it's a Vendor or a Customer, with the scope" do
      charlie = create(:user, :content_creator)
      pwc = create(:dossier_organisation, name: "PwC")
      engagement = create(:dossier_engagement, user: charlie)
      alpha = create(:dossier_assignment, engagement: engagement, project: "Alpha",
                                          client: create(:dossier_organisation, name: "Queensland Government", abbreviation: "QG"))
      beta = create(:dossier_assignment, engagement: engagement, project: "Beta",
                                         client: create(:dossier_organisation, name: "Westpac"))
      create(:dossier_assignment_partner, assignment: alpha, organisation: pwc, scope: "Built the software")
      create(:dossier_assignment_partner, :customer, assignment: beta, organisation: pwc)
      sign_in_as(charlie)
      visit dossier_organisation_path(pwc)

      within("[data-testid='organisation-as-vendor']") do
        expect(page).to have_selector("h2", text: "Your Assignments As Vendor")
        expect(page).to have_link("QG - Alpha", href: dossier_assignment_path(alpha))
        expect(page).to have_text("Built the software")
      end
      expect(page).to have_selector("[data-testid='organisation-as-customer']", text: "Westpac - Beta")
    end
  end

  describe "Negative Path (Organisation as Vendor or Customer)" do
    it "Shows nobody else your Vendor and Customer links" do
      pwc = create(:dossier_organisation, name: "PwC")
      create(:dossier_assignment_partner, organisation: pwc)
      sign_in_as(create(:user, :content_creator))
      visit dossier_organisation_path(pwc)

      expect(page).to have_selector("[data-testid='reference-data-name']", text: "PwC")
      expect(page).not_to have_selector("[data-testid='organisation-as-vendor']")
    end

    it "Won't delete an Organisation that's a Vendor or Customer" do
      pwc = create(:dossier_organisation, name: "PwC")
      create(:dossier_assignment_partner, :customer, organisation: pwc)
      sign_in_as(create(:user, :admin))
      visit dossier_organisation_path(pwc)
      click_button "Delete Organisation"

      expect(page).to have_content("Cannot delete record because dependent assignment partners exist")
      expect(Dossier::Organisation.exists?(pwc.id)).to be(true)
    end
  end

  describe "Negative Path (Organisation)" do
    it "Rejects a website that isn't an http(s) URL" do
      sign_in_as(create(:user, :admin))
      visit new_path
      fill_valid_form
      fill_in "Website", with: "northwind.example"
      click_button "Create Organisation"

      expect(page).to have_content("must start with http:// or https://")
    end

    it "Shows a visitor no Credentials panel" do
      ni = create(:dossier_organisation, name: "National Instruments")
      create(:dossier_credential, provider: ni, title: "LabVIEW Core 1")
      visit dossier_organisation_path(ni)

      expect(page).to have_selector("[data-testid='reference-data-name']", text: "National Instruments")
      expect(page).not_to have_selector("[data-testid='organisation-credentials']")
    end
  end

  describe "Products (Organisation as a Skill's vendor)" do
    let!(:microsoft) { create(:dossier_organisation, name: "Microsoft") }

    # 1) Happy Path ─────────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "Lists the Skills it makes as Products, by their shown names, to Gary too" do
        project = create(:dossier_skill, name: "Project", vendor: microsoft, show_vendor_in_name: true)
        create(:dossier_skill, name: "Excel", vendor: microsoft)
        visit dossier_organisation_path(microsoft)

        products = find("[data-testid='organisation-products']")
        expect(products.all("li").map(&:text)).to eq([ "Excel", "Microsoft Project" ])
        expect(products).to have_link("Microsoft Project", href: dossier_skill_path(project))
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "Won't delete an Organisation that is a Skill's vendor" do
        create(:dossier_skill, name: "Project", vendor: microsoft)
        sign_in_as(create(:user, :admin))
        visit dossier_organisation_path(microsoft)
        click_button "Delete Organisation"

        expect(page).to have_content("Cannot delete record because dependent products exist")
        expect(Dossier::Organisation.exists?(microsoft.id)).to be(true)
      end
    end

    # 4) Edge Cases ─────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "Shows no Products panel when it makes no Skills" do
        visit dossier_organisation_path(microsoft)

        expect(page).not_to have_selector("[data-testid='organisation-products']")
      end
    end
  end
end
