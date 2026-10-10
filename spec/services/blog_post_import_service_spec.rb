# spec/services/blog_post_import_service_spec.rb

require "rails_helper"

RSpec.describe BlogPostImportService do
  let(:user) { create(:user, :content_creator) }

  def csv_for(rows)
    CSV.generate(headers: true) do |csv|
      csv << BlogPostImportService::HEADERS
      rows.each { |row| csv << row }
    end
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a post as a Draft, Restricted, with the current user as author" do
      category = create(:blog_category, name: "Technology")
      file = StringIO.new(csv_for([ [ "My Post", "Technology", "Ruby", "Rails", "Some **bold** text." ] ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(result.failed_count).to eq(0)

      post = BlogPost.find_by!(title: "My Post")
      expect(post.user).to eq(user)
      expect(post.blog_category).to eq(category)
      expect(post.subject).to eq("Ruby")
      expect(post.topic).to eq("Rails")
      expect(post.body).to eq("Some **bold** text.")
      expect(post.published?).to be false
      expect(post.classification).to eq("restricted")
    end

    it "Imports multiple rows in one file" do
      file = StringIO.new(csv_for([
        [ "First Post", "", "", "", "Body one" ],
        [ "Second Post", "", "", "", "Body two" ]
      ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(2)
      expect(BlogPost.where(user: user).count).to eq(2)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Fails a row with a blank Title and reports the row number" do
      file = StringIO.new(csv_for([ [ "", "", "", "", "Body" ] ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:row]).to eq(2)
      expect(result.errors.first[:message]).to match(/Title/)
    end

    it "Fails a row with a Topic but no Subject (model validation)" do
      file = StringIO.new(csv_for([ [ "Bad Row", "", "", "Rails", "Body" ] ]))

      result = described_class.new(user, file).import

      expect(result.failed_count).to eq(1)
    end

    it "Continues importing later rows after an earlier row fails" do
      file = StringIO.new(csv_for([
        [ "", "", "", "", "Body" ],
        [ "Good Post", "", "", "", "Body" ]
      ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(result.failed_count).to eq(1)
      expect(BlogPost.find_by(title: "Good Post")).to be_present
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Leaves the post uncategorized when the Category name doesn't match any existing category" do
      file = StringIO.new(csv_for([ [ "My Post", "No Such Category", "", "", "Body" ] ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(BlogPost.find_by!(title: "My Post").blog_category).to be_nil
    end

    it "Matches an existing Category case-insensitively" do
      category = create(:blog_category, name: "Technology")
      file = StringIO.new(csv_for([ [ "My Post", "technology", "", "", "Body" ] ]))

      described_class.new(user, file).import

      expect(BlogPost.find_by!(title: "My Post").blog_category).to eq(category)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Returns zero counts for a file with only a header row" do
      file = StringIO.new(csv_for([]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(0)
      expect(result.errors).to eq([])
    end

    it "Creates a post with a blank Body" do
      file = StringIO.new(csv_for([ [ "Empty Body Post", "", "", "", "" ] ]))

      result = described_class.new(user, file).import

      expect(result.imported_count).to eq(1)
      expect(BlogPost.find_by!(title: "Empty Body Post").body).to eq("")
    end

    it "Reports a duplicate title (per-user uniqueness) as a failed row" do
      create(:blog_post, user: user, title: "Existing Post")
      file = StringIO.new(csv_for([ [ "Existing Post", "", "", "", "Body" ] ]))

      result = described_class.new(user, file).import

      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:message]).to match(/Title/)
    end
  end
end
