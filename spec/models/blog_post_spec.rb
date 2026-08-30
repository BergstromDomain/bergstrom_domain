# spec/models/blog_post_spec.rb
require "rails_helper"

RSpec.describe BlogPost, type: :model do
  let(:owner)   { create(:user) }
  let(:other)   { create(:user) }
  let(:contact) { create(:user) }

  # ── Database columns ──────────────────────────────────────────────────────
  describe "database columns" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:body).of_type(:text) }
    it { is_expected.to have_db_column(:format).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:sub_category).of_type(:string) }
    it { is_expected.to have_db_column(:topic).of_type(:string) }
    it { is_expected.to have_db_column(:published_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:deleted_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:comments_count).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:likes_count).of_type(:integer).with_options(null: false, default: 0) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:blog_category).optional }
    it { is_expected.to have_many(:blog_post_authors).dependent(:destroy) }
    it { is_expected.to have_many(:authors).through(:blog_post_authors).source(:user) }
    it { is_expected.to have_one_attached(:blog_image) }
  end

  # ── format enum ───────────────────────────────────────────────────────────
  describe "format" do
    it { is_expected.to define_enum_for(:format).with_values(raw: "raw", formatted: "formatted").backed_by_column_of_type(:string) }

    it "defaults to formatted" do
      expect(BlogPost.new.format).to eq("formatted")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  describe "validations" do
    # 1) Happy path ───────────────────────────────────────────────────────────
    describe "happy path" do
      it "is valid with just a title and a user" do
        post = build(:blog_post, user: owner)
        expect(post).to be_valid
      end

      it "is valid with a topic when sub_category is also present" do
        post = build(:blog_post, user: owner, sub_category: "Ruby", topic: "Rails")
        expect(post).to be_valid
      end

      it "is valid with a JPEG blog image" do
        post = build(:blog_post, user: owner)
        post.blog_image.attach(
          io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename:     "test_image.jpg",
          content_type: "image/jpeg"
        )
        expect(post).to be_valid
      end

      it "is valid to publish when Category and body are both present" do
        category = create(:blog_category)
        post = build(:blog_post, :published, user: owner, blog_category: category, body: "Some content.")
        expect(post).to be_valid
      end
    end

    # 2) Negative path ────────────────────────────────────────────────────────
    describe "negative path" do
      it "is invalid without a title" do
        post = build(:blog_post, title: nil, user: owner)
        expect(post).not_to be_valid
        expect(post.errors[:title]).to include("can't be blank")
      end

      it "is invalid without a user" do
        post = build(:blog_post, user: nil)
        expect(post).not_to be_valid
        expect(post.errors[:user]).to include("must exist")
      end

      it "is invalid when the same user reuses a title (same case)" do
        create(:blog_post, title: "My Post", user: owner)
        post = build(:blog_post, title: "My Post", user: owner)
        expect(post).not_to be_valid
        expect(post.errors[:title]).to include("has already been taken")
      end

      it "is invalid when the same user reuses a title (different case)" do
        create(:blog_post, title: "My Post", user: owner)
        post = build(:blog_post, title: "my post", user: owner)
        expect(post).not_to be_valid
      end

      it "is invalid when topic is set without sub_category" do
        post = build(:blog_post, user: owner, sub_category: nil, topic: "Rails")
        expect(post).not_to be_valid
        expect(post.errors[:sub_category]).to include("must be present if Topic is set")
      end

      it "is invalid with a non-image file as the blog image" do
        post = build(:blog_post, user: owner)
        post.blog_image.attach(
          io:           StringIO.new("not an image"),
          filename:     "bad.txt",
          content_type: "text/plain"
        )
        expect(post).not_to be_valid
        expect(post.errors[:blog_image]).to be_present
      end

      it "is invalid with a blog image exceeding 5MB" do
        post = build(:blog_post, user: owner)
        post.blog_image.attach(
          io:           StringIO.new("0" * (5.megabytes + 1)),
          filename:     "huge.jpg",
          content_type: "image/jpeg"
        )
        expect(post).not_to be_valid
        expect(post.errors[:blog_image]).to be_present
      end

      it "is invalid to publish without a Category" do
        post = build(:blog_post, :published, user: owner, blog_category: nil, body: "Some content.")
        expect(post).not_to be_valid
        expect(post.errors[:blog_category]).to include("can't be blank")
      end

      it "is invalid to publish without a body" do
        category = create(:blog_category)
        post = build(:blog_post, :published, user: owner, blog_category: category, body: nil)
        expect(post).not_to be_valid
        expect(post.errors[:body]).to include("can't be blank")
      end
    end

    # 3) Alternative path ─────────────────────────────────────────────────────
    describe "alternative path" do
      it "allows two different users to share the same title" do
        create(:blog_post, title: "My Post", user: owner)
        post = build(:blog_post, title: "My Post", user: other)
        expect(post).to be_valid
      end
    end

    # 4) Edge cases ────────────────────────────────────────────────────────────
    describe "edge cases" do
      it "is valid with sub_category present and topic blank" do
        post = build(:blog_post, user: owner, sub_category: "Ruby", topic: nil)
        expect(post).to be_valid
      end

      it "does not require a Category or body while still a draft" do
        post = build(:blog_post, user: owner, blog_category: nil, body: nil)
        expect(post).to be_valid
      end
    end
  end

  # ── FriendlyId ────────────────────────────────────────────────────────────
  describe "FriendlyId" do
    it "generates a slug from title on create" do
      post = create(:blog_post, title: "Hello World", user: owner)
      expect(post.slug).to eq("hello-world")
    end

    it "falls back to a title-and-user_id slug when two different users share a title" do
      first  = create(:blog_post, title: "Shared Title", user: owner)
      second = create(:blog_post, title: "Shared Title", user: other)
      expect(first.slug).to eq("shared-title")
      expect(second.slug).to eq("shared-title-#{other.id}")
    end
  end

  # ── Authors ───────────────────────────────────────────────────────────────
  describe "authors" do
    it "automatically adds the creating user as an author" do
      post = create(:blog_post, user: owner)
      expect(post.authors).to contain_exactly(owner)
    end

    it "includes an added co-author alongside the original author" do
      post = create(:blog_post, user: owner)
      post.blog_post_authors.create!(user: other)
      expect(post.reload.authors).to contain_exactly(owner, other)
    end
  end

  # ── Markdown rendering ────────────────────────────────────────────────────
  describe ".render_markdown / #rendered_body" do
    it "converts Markdown to HTML" do
      html = BlogPost.render_markdown("# Hello\n\nSome **bold** text.")
      expect(html).to include("<h1>Hello</h1>")
      expect(html).to include("<strong>bold</strong>")
    end

    it "does not add heading anchor links" do
      html = BlogPost.render_markdown("# Hello")
      expect(html).to eq("<h1>Hello</h1>\n")
    end

    it "#rendered_body renders the post's own body" do
      post = build(:blog_post, user: owner, body: "Some **bold** text.")
      expect(post.rendered_body).to include("<strong>bold</strong>")
    end

    it "does not raise on a nil body (e.g. a fresh draft)" do
      expect(BlogPost.render_markdown(nil)).to eq("")
    end
  end

  # ── published? ────────────────────────────────────────────────────────────
  describe "#published?" do
    it "is false when published_at is nil" do
      expect(build(:blog_post, published_at: nil)).not_to be_published
    end

    it "is true when published_at is set" do
      expect(build(:blog_post, :published)).to be_published
    end
  end

  # ── Visibility ────────────────────────────────────────────────────────────
  describe "visibility" do
    let!(:published_unrestricted) { create(:blog_post, :unrestricted, :published, user: owner) }
    let!(:draft_unrestricted)     { create(:blog_post, :unrestricted, user: owner) }
    let!(:published_contacts)     { create(:blog_post, :contacts, :published, user: owner) }
    let!(:draft_contacts)         { create(:blog_post, :contacts, user: owner) }
    let!(:published_restricted)   { create(:blog_post, :restricted, :published, user: owner) }

    before { create(:contact, user: owner, contact: contact, status: "confirmed") }

    describe ".visible_to_visitors" do
      it "returns only published, unrestricted posts" do
        expect(BlogPost.visible_to_visitors).to contain_exactly(published_unrestricted)
      end
    end

    describe ".visible_to_users" do
      it "always includes the author's own drafts, regardless of classification" do
        expect(BlogPost.visible_to_users(owner)).to include(draft_unrestricted, draft_contacts)
      end

      it "never includes another user's draft, even one they could otherwise read once published" do
        expect(BlogPost.visible_to_users(contact)).not_to include(draft_contacts)
        expect(BlogPost.visible_to_users(other)).not_to include(draft_unrestricted)
      end

      it "applies normal classification rules to published posts" do
        expect(BlogPost.visible_to_users(contact)).to include(published_contacts)
        expect(BlogPost.visible_to_users(other)).not_to include(published_contacts)
        expect(BlogPost.visible_to_users(other)).not_to include(published_restricted)
      end

      it "includes a co-author's own draft" do
        draft_unrestricted.blog_post_authors.create!(user: other)
        expect(BlogPost.visible_to_users(other)).to include(draft_unrestricted)
      end
    end

    describe ".visible_to_admins" do
      it "returns every kept post regardless of draft/published/classification" do
        expect(BlogPost.visible_to_admins).to include(
          published_unrestricted, draft_unrestricted, published_contacts,
          draft_contacts, published_restricted
        )
      end

      it "excludes soft-deleted posts" do
        published_unrestricted.update!(deleted_at: Time.current)
        expect(BlogPost.visible_to_admins).not_to include(published_unrestricted)
      end
    end
  end

  # ── Soft delete scopes ────────────────────────────────────────────────────
  describe "kept/discarded scopes" do
    it "kept excludes soft-deleted posts" do
      kept_post      = create(:blog_post, user: owner)
      discarded_post = create(:blog_post, user: owner, deleted_at: Time.current)
      expect(BlogPost.kept).to include(kept_post)
      expect(BlogPost.kept).not_to include(discarded_post)
    end

    it "discarded returns only soft-deleted posts" do
      kept_post      = create(:blog_post, user: owner)
      discarded_post = create(:blog_post, user: owner, deleted_at: Time.current)
      expect(BlogPost.discarded).to contain_exactly(discarded_post)
      expect(BlogPost.discarded).not_to include(kept_post)
    end
  end
end
