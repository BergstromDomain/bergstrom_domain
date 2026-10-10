# spec/services/blog_post_full_export_service_spec.rb

require "rails_helper"

RSpec.describe BlogPostFullExportService do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  def entries_from(zip_data)
    entries = {}
    Zip::InputStream.open(StringIO.new(zip_data)) do |io|
      while (entry = io.get_next_entry)
        entries[entry.name] = io.read
      end
    end
    entries
  end

  def csv_rows_from(entries)
    csv_entry = entries.keys.find { |name| name.start_with?("csv/") }
    CSV.parse(entries.fetch(csv_entry), headers: true)
  end

  def attach_blog_image(post)
    post.blog_image.attach(
      io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
      filename:     "test_image.jpg",
      content_type: "image/jpeg"
    )
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Returns a zip with a CSV under csv/ and the header row" do
      entries = entries_from(described_class.new([]).generate_zip)

      csv_entry = entries.keys.find { |name| name.start_with?("csv/") && name.end_with?(".csv") }
      expect(csv_entry).to be_present
      expect(entries[csv_entry]).to include(*BlogPostFullExportService::HEADERS)
    end

    it "Includes one CSV row per post with every column populated" do
      category = create(:blog_category, name: "Technology")
      post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
        subject: "Ruby", topic: "Rails", title: "My Post", body: "# Heading\n\nSome text.")

      rows = csv_rows_from(entries_from(described_class.new([ post ]).generate_zip))
      row = rows.first

      expect(row["Title"]).to eq("My Post")
      expect(row["Category"]).to eq("Technology")
      expect(row["Subject"]).to eq("Ruby")
      expect(row["Topic"]).to eq("Rails")
      expect(row["Authors"]).to eq("Ada Lovelace")
      expect(row["Classification"]).to eq("unrestricted")
      expect(row["Published"]).to eq("Yes")
      expect(row["Published Date"]).to eq(post.published_at.strftime("%d-%b-%Y"))
      expect(row["Created Date"]).to eq(post.created_at.strftime("%d-%b-%Y"))
      expect(row["Body (Markdown)"]).to eq("# Heading\n\nSome text.")
    end

    it "Lists every author, primary first, semicolon-separated" do
      coauthor = create(:user, :content_creator, first_name: "Grace", last_name: "Hopper")
      post = create(:blog_post, user: owner, title: "Co-Authored")
      post.blog_post_authors.find_or_create_by!(user: coauthor)

      rows = csv_rows_from(entries_from(described_class.new([ post ]).generate_zip))
      expect(rows.first["Authors"]).to eq("Ada Lovelace; Grace Hopper")
    end

    it "Bundles the header blog image under images/<slug>/ and references it in the CSV" do
      post = create(:blog_post, user: owner, title: "With Header Image")
      attach_blog_image(post)

      entries = entries_from(described_class.new([ post ]).generate_zip)
      rows = csv_rows_from(entries)
      header_path = rows.first["Header Image"]

      expect(header_path).to eq("images/#{post.slug}/blog_image.jpg")
      expect(entries[header_path]).to eq(post.blog_image.blob.download)
    end

    it "Extracts a base64 inline body image into images/<slug>/ and rewrites the Markdown reference" do
      pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
      post = create(:blog_post, user: owner, title: "Inline Image Post",
        body: "Text\n\n![An image](data:image/png;base64,#{pixel})")

      entries = entries_from(described_class.new([ post ]).generate_zip)
      rows = csv_rows_from(entries)
      body = rows.first["Body (Markdown)"]
      expected_path = "images/#{post.slug}/body_1.png"

      expect(body).to include("![An image](#{expected_path})")
      expect(entries[expected_path]).to eq(Base64.decode64(pixel))
    end

    it "Extracts a relative ActiveStorage body image into images/<slug>/ and rewrites the Markdown reference" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "inline.jpg",
        content_type: "image/jpeg"
      )
      post = create(:blog_post, user: owner, title: "Relative Image Post",
        body: "![Inline](/rails/active_storage/blobs/#{blob.signed_id}/inline.jpg)")

      entries = entries_from(described_class.new([ post ]).generate_zip)
      rows = csv_rows_from(entries)
      body = rows.first["Body (Markdown)"]
      expected_path = "images/#{post.slug}/body_1.jpg"

      expect(body).to include("![Inline](#{expected_path})")
      expect(entries[expected_path]).to eq(blob.download)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns just the header row and no image entries for an empty post list" do
      entries = entries_from(described_class.new([]).generate_zip)

      expect(csv_rows_from(entries).length).to eq(0)
      expect(entries.keys).not_to include(a_string_starting_with("images/"))
    end

    it "Leaves Header Image blank for a post with no blog image" do
      post = create(:blog_post, user: owner, title: "No Image Post")

      rows = csv_rows_from(entries_from(described_class.new([ post ]).generate_zip))
      expect(rows.first["Header Image"]).to be_nil
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Marks a draft post as not Published, with a blank Published Date" do
      post = create(:blog_post, user: owner, title: "Draft Post")

      rows = csv_rows_from(entries_from(described_class.new([ post ]).generate_zip))
      expect(rows.first["Published"]).to eq("No")
      expect(rows.first["Published Date"]).to be_nil
    end

    it "Uses a per-post slug subfolder so two posts' images never collide" do
      post_a = create(:blog_post, user: owner, title: "Post A")
      post_b = create(:blog_post, user: owner, title: "Post B")
      attach_blog_image(post_a)
      attach_blog_image(post_b)

      entries = entries_from(described_class.new([ post_a, post_b ]).generate_zip)

      expect(entries.keys).to include("images/#{post_a.slug}/blog_image.jpg", "images/#{post_b.slug}/blog_image.jpg")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves an unresolvable image reference untouched rather than raising" do
      post = create(:blog_post, user: owner, title: "Broken Image Post",
        body: "![Missing](https://example.com/not-local.png)")

      rows = csv_rows_from(entries_from(described_class.new([ post ]).generate_zip))
      expect(rows.first["Body (Markdown)"]).to include("https://example.com/not-local.png")
    end

    it "Numbers multiple inline body images sequentially within the same post" do
      pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
      post = create(:blog_post, user: owner, title: "Two Images",
        body: "![One](data:image/png;base64,#{pixel})\n\n![Two](data:image/png;base64,#{pixel})")

      entries = entries_from(described_class.new([ post ]).generate_zip)

      expect(entries.keys).to include("images/#{post.slug}/body_1.png", "images/#{post.slug}/body_2.png")
    end
  end
end
