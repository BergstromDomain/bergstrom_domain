# spec/services/browse_tree_spec.rb

require "rails_helper"

# BrowseTree is app-agnostic — BlogPost is used here only as a convenient
# concrete model; nothing in the service itself knows about Chronicle.
RSpec.describe BrowseTree do
  let(:owner)      { create(:user, :content_creator) }
  let!(:food)       { create(:blog_category, name: "Food") }
  let!(:technology) { create(:blog_category, name: "Technology") }

  let(:levels) do
    [
      BrowseTree::Level.new(key: :category_id, association: :blog_category, records: BlogCategory.order("LOWER(name) ASC")),
      BrowseTree::Level.new(key: :subject, column: :subject),
      BrowseTree::Level.new(key: :topic,   column: :topic)
    ]
  end

  def tree(params = {})
    described_class.new(scope: BlogPost.all, levels: levels, params: params)
  end

  def post(category, subject: nil, topic: nil, created_at: Time.current)
    create(:blog_post, user: owner, blog_category: category, subject: subject, topic: topic, created_at: created_at)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Lists every first-level record with its count at the root, and no items" do
      post(technology)
      post(technology)

      root = tree

      expect(root.total_count).to eq(2)
      expect(root.depth).to eq(0)
      expect(root.children.map { |node| [ node.label, node.count ] }).to eq([ [ "Food", 0 ], [ "Technology", 2 ] ])
      expect(root.items).to be_nil
    end

    it "Lists a Category's Subjects and every post in the Category, newest first" do
      older = post(technology, subject: "Ruby", created_at: 2.days.ago)
      newer = post(technology, subject: "Java", created_at: 1.day.ago)
      post(food, subject: "Baking")

      level = tree(category_id: technology.slug)

      expect(level.path.map { |node| [ node.label, node.count ] }).to eq([ [ "Technology", 2 ] ])
      expect(level.children.map { |node| [ node.label, node.count ] }).to eq([ [ "Java", 1 ], [ "Ruby", 1 ] ])
      expect(level.items.to_a).to eq([ newer, older ])
    end

    it "Lists a Subject's Topics and every post with that Subject" do
      rails = post(technology, subject: "Ruby", topic: "Rails")
      post(technology, subject: "Ruby", topic: "Sinatra")
      post(technology, subject: "Java", topic: "Spring")

      level = tree(category_id: technology.slug, subject: "Ruby")

      expect(level.path.map(&:label)).to eq([ "Technology", "Ruby" ])
      expect(level.children.map { |node| [ node.label, node.count ] }).to eq([ [ "Rails", 1 ], [ "Sinatra", 1 ] ])
      expect(level.items).to include(rails)
      expect(level.items.count).to eq(2)
    end

    it "Treats the last level as a leaf with items but no children" do
      rails = post(technology, subject: "Ruby", topic: "Rails")

      level = tree(category_id: technology.slug, subject: "Ruby", topic: "Rails")

      expect(level).to be_leaf
      expect(level.children).to be_nil
      expect(level.items.to_a).to eq([ rails ])
    end

    it "Gives each node the params needed to link to it" do
      level = tree(category_id: technology.slug, subject: "Ruby")

      expect(level.path.map(&:params)).to eq([
        { category_id: technology.slug },
        { category_id: technology.slug, subject: "Ruby" }
      ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Flags an unknown first-level record as invalid" do
      expect(tree(category_id: "no-such-category")).to be_invalid
    end

    it "Ignores a deeper param when the level above it isn't selected" do
      level = tree(subject: "Ruby")

      expect(level.depth).to eq(0)
      expect(level.items).to be_nil
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Only counts and lists what the given scope allows" do
      visible = post(technology)
      post(technology).update!(deleted_at: Time.current)

      level = described_class.new(scope: BlogPost.kept, levels: levels, params: { category_id: technology.slug })

      expect(level.path.first.count).to eq(1)
      expect(level.items.to_a).to eq([ visible ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Never lists a blank Subject or Topic as a child, but still lists those posts as items" do
      bare = post(technology, subject: nil)
      post(technology, subject: "")
      post(technology, subject: "Ruby")

      level = tree(category_id: technology.slug)

      expect(level.children.map(&:label)).to eq([ "Ruby" ])
      expect(level.items).to include(bare)
      expect(level.items.count).to eq(3)
    end

    it "Sorts string children case-insensitively" do
      post(technology, subject: "ruby")
      post(technology, subject: "Java")

      expect(tree(category_id: technology.slug).children.map(&:label)).to eq([ "Java", "ruby" ])
    end

    it "Finds a first-level record by an old FriendlyId slug" do
      old_slug = technology.slug
      technology.update!(name: "Tech")

      expect(tree(category_id: old_slug)).not_to be_invalid
    end

    it "Returns zero items for a Subject with no posts rather than erroring" do
      level = tree(category_id: technology.slug, subject: "Nothing Here")

      expect(level.path.last.count).to eq(0)
      expect(level.items).to be_empty
    end
  end
end
