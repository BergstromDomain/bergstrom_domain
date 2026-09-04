# spec/services/blog_post_filter_spec.rb

require "rails_helper"

RSpec.describe BlogPostFilter do
  let(:owner) { create(:user, :content_creator, first_name: "Ada", last_name: "Lovelace") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    describe ".attributes_for" do
      it "Builds the full attribute hash for a post" do
        category = create(:blog_category, name: "Technology")
        post = create(:blog_post, :unrestricted, :published, user: owner, blog_category: category,
          subject: "Ruby", topic: "Rails", title: "My Post")
        create(:comment, blog_post: post, user: owner)

        attrs = described_class.attributes_for(post)

        expect(attrs).to eq(
          category:  "Technology",
          subject:   "Ruby",
          topic:     "Rails",
          title:     "My Post",
          author:    "Ada Lovelace",
          created:   post.created_at,
          comments:  1,
          smiles:    post.like_score,
          published: true
        )
      end

      it "Uses nil for Category when the post has none" do
        post = create(:blog_post, user: owner, blog_category: nil)
        expect(described_class.attributes_for(post)[:category]).to be_nil
      end
    end

    describe ".basic_ast" do
      it "Returns nil (no filter) when every argument is blank" do
        expect(described_class.basic_ast).to be_nil
      end

      it "Builds an AST that matches only on the given Category" do
        ast = described_class.basic_ast(category: "Technology")
        expect(described_class::EVALUATOR.matches?(ast, category: "Technology", subject: nil, topic: nil,
          title: "X", author: "A B", created: Time.current, comments: 0, smiles: 3.0)).to be true
        expect(described_class::EVALUATOR.matches?(ast, category: "Food", subject: nil, topic: nil,
          title: "X", author: "A B", created: Time.current, comments: 0, smiles: 3.0)).to be false
      end

      it "Combines multiple filters with AND" do
        ast = described_class.basic_ast(category: "Technology", topic: "Rails")
        base = { category: "Technology", subject: nil, topic: "Rails", title: "X", author: "A B",
                 created: Time.current, comments: 0, smiles: 3.0 }

        expect(described_class::EVALUATOR.matches?(ast, base)).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(topic: "Java"))).to be false
      end

      it "Builds an AST that matches only on the given Published status" do
        ast = described_class.basic_ast(published: "true")
        base = { category: nil, subject: nil, topic: nil, title: "X", author: "A B",
                 created: Time.current, comments: 0, smiles: 3.0 }

        expect(described_class::EVALUATOR.matches?(ast, base.merge(published: true))).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(published: false))).to be false
      end

      it "Filters by the Created range boundaries" do
        range = Date.new(2026, 1, 1)..Date.new(2026, 1, 31)
        ast = described_class.basic_ast(created_range: range)
        base = { category: nil, subject: nil, topic: nil, title: "X", author: "A B",
                 comments: 0, smiles: 3.0 }

        expect(described_class::EVALUATOR.matches?(ast, base.merge(created: Time.zone.local(2026, 1, 15)))).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(created: Time.zone.local(2026, 2, 1)))).to be false
        expect(described_class::EVALUATOR.matches?(ast, base.merge(created: Time.zone.local(2025, 12, 31)))).to be false
      end
    end

    describe ".sort" do
      it "Sorts posts by Title ascending and descending" do
        b = create(:blog_post, user: owner, title: "Banana")
        a = create(:blog_post, user: owner, title: "Apple")

        expect(described_class.sort([ b, a ], :title, "asc")).to eq([ a, b ])
        expect(described_class.sort([ b, a ], :title, "desc")).to eq([ b, a ])
      end

      it "Sorts posts by Comments (an integer column)" do
        few = create(:blog_post, user: owner, title: "Few")
        many = create(:blog_post, user: owner, title: "Many")
        create(:comment, blog_post: many, user: owner)
        create(:comment, blog_post: many, user: owner)

        expect(described_class.sort([ few, many ], :comments, "asc")).to eq([ few, many ])
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    describe ".basic_ast" do
      it "Ignores a blank string filter rather than matching an empty value" do
        ast = described_class.basic_ast(category: "")
        expect(ast).to be_nil
      end
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    describe ".sort" do
      it "Sorts by Smiles using the computed like_score, not a stored column" do
        low = create(:blog_post, user: owner, title: "Low")
        high = create(:blog_post, user: owner, title: "High")
        create(:like, blog_post: high, user: owner, face: "grinning")

        expect(described_class.sort([ low, high ], :smiles, "desc").first).to eq(high)
      end
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    describe ".sort" do
      it "Sorts posts missing a Subject last, regardless of direction" do
        with_subject = create(:blog_post, user: owner, title: "A", subject: "Ruby")
        without_subject = create(:blog_post, user: owner, title: "B", subject: nil)

        expect(described_class.sort([ without_subject, with_subject ], :subject, "asc").last).to eq(without_subject)
        expect(described_class.sort([ without_subject, with_subject ], :subject, "desc").last).to eq(without_subject)
      end

      it "Sorts Title case-insensitively" do
        upper = create(:blog_post, user: owner, title: "Zebra")
        lower = create(:blog_post, user: owner, title: "apple")

        expect(described_class.sort([ upper, lower ], :title, "asc")).to eq([ lower, upper ])
      end
    end

    describe ".basic_ast" do
      it "Combines Author and Published, the exact shape the 'My Posts' nav links produce" do
        ast = described_class.basic_ast(author_name: "Ada Lovelace", published: "false")
        base = { category: nil, subject: nil, topic: nil, title: "X", created: Time.current,
                 comments: 0, smiles: 3.0 }

        expect(described_class::EVALUATOR.matches?(ast, base.merge(author: "Ada Lovelace", published: false))).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(author: "Ada Lovelace", published: true))).to be false
        expect(described_class::EVALUATOR.matches?(ast, base.merge(author: "Someone Else", published: false))).to be false
      end
    end
  end
end
