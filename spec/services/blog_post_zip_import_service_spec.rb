# spec/services/blog_post_zip_import_service_spec.rb

require "rails_helper"

RSpec.describe BlogPostZipImportService do
  let(:user) { create(:user, :content_creator) }

  def zip_for(entries)
    buffer = Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end
    StringIO.new(buffer.string)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a Draft, Restricted post titled from the markdown filename" do
      file = zip_for("My_Great_Post.md" => "# Hello\n\nSome body text.")

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(result.failed_count).to eq(0)

      post = BlogPost.find_by!(title: "My Great Post")
      expect(post.user).to eq(user)
      expect(post.body).to eq("# Hello\n\nSome body text.")
      expect(post.published?).to be false
      expect(post.classification).to eq("restricted")
      expect(post.blog_category).to be_nil
    end

    it "Embeds a referenced image as an inline base64 data URI" do
      file = zip_for(
        "post.md" => "Text\n\n![A photo](images/photo.png)\n",
        "images/photo.png" => "fake-png-bytes"
      )

      described_class.new(user, file).import

      body = BlogPost.find_by!(title: "post").body
      expect(body).to include("data:image/png;base64,")
      expect(body).not_to include("images/photo.png")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Fails when the zip has no Markdown file" do
      file = zip_for("readme.txt" => "hello")

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:message]).to match(/exactly one Markdown/)
    end

    it "Fails when the zip has more than one Markdown file" do
      file = zip_for("one.md" => "Body one", "two.md" => "Body two")

      result = described_class.new(user, file).import

      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:message]).to match(/exactly one Markdown/)
    end

    it "Fails gracefully when the uploaded file isn't a valid zip" do
      file = StringIO.new("not a zip file")

      result = described_class.new(user, file).import

      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:message]).to match(/zip/i)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Accepts a .markdown extension as well as .md" do
      file = zip_for("notes.markdown" => "Some content")

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(BlogPost.find_by(title: "notes")).to be_present
    end

    it "Derives the title from an underscored filename, replacing underscores with spaces" do
      file = zip_for("Getting_Started_With_Zip_Import.md" => "Body")

      described_class.new(user, file).import

      expect(BlogPost.find_by(title: "Getting Started With Zip Import")).to be_present
    end

    it "Leaves an unreferenced image file untouched in the body" do
      file = zip_for(
        "post.md"          => "Just text, no image reference.",
        "images/unused.png" => "fake-bytes"
      )

      described_class.new(user, file).import

      expect(BlogPost.find_by!(title: "post").body).to eq("Just text, no image reference.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Reports a duplicate title (per-user uniqueness) as a failed import" do
      create(:blog_post, user: user, title: "Existing Post")
      file = zip_for("Existing_Post.md" => "Body")

      result = described_class.new(user, file).import

      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:message]).to match(/Title/)
    end

    it "Embeds a JPEG image with the correct content type" do
      file = zip_for(
        "post.md"          => "![Photo](photo.jpg)",
        "photo.jpg"        => "fake-jpeg-bytes"
      )

      described_class.new(user, file).import

      expect(BlogPost.find_by!(title: "post").body).to include("data:image/jpeg;base64,")
    end
  end
end
