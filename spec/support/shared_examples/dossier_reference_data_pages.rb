# spec/support/shared_examples/dossier_reference_data_pages.rb

# Shared feature examples for the Dossier reference-data pages (list, show,
# create, edit, delete). Each including spec defines:
#   let(:factory)       — FactoryBot factory name
#   let(:model)         — the model class
#   let(:singular)      — button/heading noun, e.g. "Industry"
#   let(:plural)        — page title, e.g. "Industries"
#   let(:index_path)    — the list page path
#   let(:new_path)      — the new page path
#   let(:record_name)   — the name the record is shown and toasted with
#   def fill_valid_form — fills in a valid form that creates record_name
#   def fill_name(text) — fills in the identifying field(s) with text
# and passes `content_creators_can_create:` (Organisations and Skills: true).
RSpec.shared_examples "Dossier reference data pages" do |content_creators_can_create:|
  let(:admin)   { create(:user, :admin) }
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists records alphabetically and links to each one" do
      create(factory, **sortable_attributes("beta"))
      create(factory, **sortable_attributes("Alpha"))
      visit index_path

      expect(page).to have_selector("h1.page-title", text: plural)
      names = all("[data-testid='reference-data-name']").map(&:text)
      expect(names.first).to include("Alpha")
      expect(names.last).to include("beta")
    end

    it "Lets an admin create one, with a toast" do
      sign_in_as(admin)
      visit new_path
      fill_valid_form
      click_button "Create #{singular}"

      expect(page).to have_selector("h1.page-title", text: record_name)
      expect(page).to have_css("[data-testid='flash-success']", text: "#{record_name} has been successfully created")
    end

    it "Lets an admin edit one, with a toast" do
      record = create(factory)
      sign_in_as(admin)
      visit polymorphic_path(record)
      click_link "Edit #{singular}"
      fill_valid_form
      click_button "Update #{singular}"

      expect(page).to have_selector("h1.page-title", text: record_name)
      expect(page).to have_css("[data-testid='flash-success']", text: "#{record_name} has been successfully updated")
    end

    it "Lets an admin delete an unused one, with a toast" do
      record = create(factory)
      label = record.to_toast_label
      sign_in_as(admin)
      visit polymorphic_path(record)

      expect { click_button "Delete #{singular}" }.to change(model, :count).by(-1)
      expect(page).to have_current_path(index_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "#{label} has been successfully deleted")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Shows an error and saves nothing when the name is blank" do
      sign_in_as(admin)
      visit new_path
      fill_valid_form
      fill_name("")
      click_button "Create #{singular}"

      expect(page).to have_selector("[data-testid='field-error']", text: "can't be blank")
      expect(model.count).to eq(0)
    end

    it "Shows an error for a duplicate in a different case" do
      sign_in_as(admin)
      visit new_path
      fill_valid_form
      click_button "Create #{singular}"
      visit new_path
      fill_valid_form
      fill_name(record_name.swapcase)
      click_button "Create #{singular}"

      expect(page).to have_content("has already been taken")
      expect(model.count).to eq(1)
    end

    it "Sends 'Gary Guest' to the 'Sign in' page from the new page" do
      visit new_path
      expect(page).to have_current_path(new_session_path)
    end

    it "Sends 'Uno User' back to the list from the new page" do
      sign_in_as(uno)
      visit new_path
      expect(page).to have_current_path(index_path)
    end

    it "Shows a Content Creator no Edit or Delete buttons, and sends them back from the edit page" do
      record = create(factory)
      sign_in_as(charlie)
      visit polymorphic_path(record)
      expect(page).not_to have_link("Edit #{singular}")
      expect(page).not_to have_button("Delete #{singular}")

      visit polymorphic_path(record, action: :edit)
      expect(page).to have_current_path(index_path)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    if content_creators_can_create
      it "Lets a Content Creator create one" do
        sign_in_as(charlie)
        visit new_path
        fill_valid_form
        click_button "Create #{singular}"
        expect(page).to have_css("[data-testid='flash-success']", text: "#{record_name} has been successfully created")
      end
    else
      it "Sends a Content Creator back to the list from the new page" do
        sign_in_as(charlie)
        visit new_path
        expect(page).to have_current_path(index_path)
      end
    end

    it "Lets 'Gary Guest' see the list and a record's page" do
      record = create(factory)
      visit index_path
      click_link record.to_toast_label
      expect(page).to have_selector("h1.page-title", text: record.to_toast_label)
      expect(page).to have_link("Back", href: index_path)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Shows an empty state when there are none" do
      visit index_path
      expect(page).to have_selector("[data-testid='empty-state']")
    end

    it "Keeps the Dossier left nav on its pages" do
      visit index_path
      within("[data-testid='left-nav']") do
        expect(page).to have_link(plural, href: index_path)
      end
    end
  end
end
