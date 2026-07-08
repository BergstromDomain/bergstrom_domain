# spec/features/import/import_template_spec.rb
require "rails_helper"

RSpec.describe "Import Template", type: :feature do
  describe "Happy path" do
    it "Downloads a CSV file with the correct headers and one example row per event type" do
      create(:event_type, name: "Anniversary")
      create(:event_type, name: "Birthday")

      page.driver.submit :get, import_template_path, {}

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to include("import_template.csv")

      lines = page.body.strip.split("\n")
      expect(lines.first).to eq("First name,Last name,Event type,Event title,Event date")
      expect(lines.length).to eq(3)
      expect(lines[1]).to include("Anniversary")
      expect(lines[2]).to include("Birthday")
    end

    it "Uses the exact event type name and placeholder values for the other columns" do
      create(:event_type, name: "Birthday")

      page.driver.submit :get, import_template_path, {}

      row = page.body.strip.split("\n").last
      expect(row).to include("[First name]")
      expect(row).to include("[Last name]")
      expect(row).to include("Birthday")
      expect(row).to include("[Event title]")
      expect(row).to include("YYYY-MM-DD")
    end
  end

  describe "Alternative path" do
    it "Downloads a headers-only CSV when no event types exist" do
      page.driver.submit :get, import_template_path, {}

      lines = page.body.strip.split("\n")
      expect(lines.length).to eq(1)
      expect(lines.first).to eq("First name,Last name,Event type,Event title,Event date")
    end
  end

  describe "Edge cases" do
    it "Is accessible to unauthenticated visitors" do
      page.driver.submit :get, import_template_path, {}
      expect(page.status_code).to eq(200)
    end

    it "Is accessible to authenticated users of any role" do
      uno = create(:user)
      sign_in_as uno

      page.driver.submit :get, import_template_path, {}
      expect(page.status_code).to eq(200)
    end
  end
end
