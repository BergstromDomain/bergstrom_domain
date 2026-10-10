# spec/services/blog_post_import_template_service_spec.rb

require "rails_helper"

RSpec.describe BlogPostImportTemplateService do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Returns a CSV with the header row" do
      rows = CSV.parse(described_class.new.generate_csv, headers: true)
      expect(rows.headers).to eq(BlogPostImportService::HEADERS)
    end

    it "Includes one placeholder row per existing Blog Category" do
      create(:blog_category, name: "Technology")
      create(:blog_category, name: "History")

      rows = CSV.parse(described_class.new.generate_csv, headers: true)

      expect(rows.map { |r| r["Category"] }).to contain_exactly("History", "Technology")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns just the header row when there are no Blog Categories" do
      rows = CSV.parse(described_class.new.generate_csv, headers: true)
      expect(rows.length).to eq(0)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Orders placeholder rows alphabetically, case-insensitively" do
      create(:blog_category, name: "zebra")
      create(:blog_category, name: "Apple")

      rows = CSV.parse(described_class.new.generate_csv, headers: true)
      expect(rows.map { |r| r["Category"] }).to eq([ "Apple", "zebra" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves Subject and Topic blank in every placeholder row" do
      create(:blog_category, name: "Technology")

      rows = CSV.parse(described_class.new.generate_csv, headers: true)
      expect(rows.first["Subject"]).to be_blank
      expect(rows.first["Topic"]).to be_blank
    end

    it "Uses bracketed placeholders for Title and Body" do
      create(:blog_category, name: "Technology")

      rows = CSV.parse(described_class.new.generate_csv, headers: true)
      expect(rows.first["Title"]).to eq("[Title]")
      expect(rows.first["Body (Markdown)"]).to eq("[Body]")
    end
  end
end
