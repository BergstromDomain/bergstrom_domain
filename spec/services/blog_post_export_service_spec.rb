# spec/services/blog_post_export_service_spec.rb

require "rails_helper"

RSpec.describe BlogPostExportService do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Returns a CSV string with the header row" do
      result = described_class.new([]).generate_csv
      expect(result).to be_a(String)
      expect(result.lines.first).to include(*BlogPostExportService::HEADERS)
    end

    it "Includes one row per post with the expected columns" do
      category = create(:blog_category, name: "Technology")
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        subject: "Ruby", topic: "Rails", title: "My Post", body: "# Heading\n\nSome text.")

      rows = CSV.parse(described_class.new([ post ]).generate_csv, headers: true)
      row = rows.first

      expect(row["Title"]).to eq("My Post")
      expect(row["Category"]).to eq("Technology")
      expect(row["Subject"]).to eq("Ruby")
      expect(row["Topic"]).to eq("Rails")
      expect(row["Author"]).to eq("Ada Lovelace")
      expect(row["Created"]).to eq(post.created_at.strftime("%d-%b-%Y"))
      expect(row["Published"]).to eq("Yes")
      expect(row["Body (Markdown)"]).to eq("# Heading\n\nSome text.")
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns just the header row for an empty post list" do
      rows = CSV.parse(described_class.new([]).generate_csv, headers: true)
      expect(rows.length).to eq(0)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Marks a draft post as not Published" do
      post = create(:blog_post, user: owner, title: "Draft Post")

      rows = CSV.parse(described_class.new([ post ]).generate_csv, headers: true)
      expect(rows.first["Published"]).to eq("No")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Leaves Category/Subject/Topic blank for a post missing them" do
      post = create(:blog_post, user: owner, title: "Bare Post", blog_category: nil, subject: nil, topic: nil)

      rows = CSV.parse(described_class.new([ post ]).generate_csv, headers: true)
      row = rows.first

      expect(row["Category"]).to be_nil
      expect(row["Subject"]).to be_nil
      expect(row["Topic"]).to be_nil
    end

    it "Passes the Body through verbatim as Markdown, not rendered HTML" do
      post = create(:blog_post, user: owner, title: "Markdown Post", body: "**bold** and _italic_")

      rows = CSV.parse(described_class.new([ post ]).generate_csv, headers: true)
      expect(rows.first["Body (Markdown)"]).to eq("**bold** and _italic_")
    end
  end
end
