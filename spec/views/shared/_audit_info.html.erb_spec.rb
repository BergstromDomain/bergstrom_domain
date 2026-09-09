# spec/views/shared/_audit_info.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_audit_info", type: :view do
  def record_double(updater: nil)
    double("AuditableRecord",
      user: double("User", email_address: "creator@example.com"),
      updater: updater,
      created_at: Time.zone.parse("2026-01-02 10:00:00"),
      updated_at: Time.zone.parse("2026-03-04 11:00:00"))
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders the Created By line with the creator's email and created date" do
      render partial: "shared/audit_info", locals: { record: record_double, testid: "show-panel-admin" }

      expect(rendered).to have_css("[data-testid='show-panel-admin']")
      expect(rendered).to have_css("[data-testid='audit-created']", text: "Created by: creator@example.com at 2 January 2026")
    end

    it "applies the given testid to the wrapping panel" do
      render partial: "shared/audit_info", locals: { record: record_double, testid: "edit-panel-admin" }

      expect(rendered).to have_css("[data-testid='edit-panel-admin']")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "omits the Updated By line when the record has never been updated" do
      render partial: "shared/audit_info", locals: { record: record_double(updater: nil), testid: "show-panel-admin" }

      expect(rendered).to have_no_css("[data-testid='audit-updated']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "renders the Updated By line with the updater's email and updated date when present" do
      updater = double("User", email_address: "editor@example.com")
      render partial: "shared/audit_info", locals: { record: record_double(updater: updater), testid: "show-panel-admin" }

      expect(rendered).to have_css("[data-testid='audit-updated']", text: "Updated by: editor@example.com at 4 March 2026")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "bolds both labels" do
      updater = double("User", email_address: "editor@example.com")
      render partial: "shared/audit_info", locals: { record: record_double(updater: updater), testid: "show-panel-admin" }

      expect(rendered).to have_css("[data-testid='audit-created'] strong", text: "Created by:")
      expect(rendered).to have_css("[data-testid='audit-updated'] strong", text: "Updated by:")
    end
  end
end
