# spec/views/blog_posts/pdf.html.erb_spec.rb
require "rails_helper"

RSpec.describe "blog_posts/pdf", type: :view do
  let(:owner) { create(:user, first_name: "Ada", last_name: "Lovelace") }

  def render_pdf(post)
    assign(:blog_post, post)
    render template: "blog_posts/pdf", layout: false
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the comment count and 'No reactions yet' when nobody has reacted" do
      post = create(:blog_post, user: owner)
      create(:comment, commentable: post, user: owner)

      render_pdf(post)

      expect(rendered).to have_css(".pdf-reactions", text: "1 comment")
      expect(rendered).to have_css(".pdf-reactions", text: "No reactions yet")
    end

    it "Shows the reaction score and total count once the post has reactions" do
      post = create(:blog_post, user: owner)
      post.likes.create!(user: create(:user), face: "grinning")

      render_pdf(post)

      expect(rendered).to have_css(".pdf-reactions", text: "5.0 reaction score")
      expect(rendered).to have_css(".pdf-reactions", text: "1 reaction")
    end

    it "Lists each top-level comment with its author and body" do
      post = create(:blog_post, user: owner)
      create(:comment, commentable: post, user: owner, body: "Great post!")

      render_pdf(post)

      expect(rendered).to have_css(".pdf-comment .pdf-comment__meta", text: "Ada Lovelace")
      expect(rendered).to have_css(".pdf-comment .pdf-comment__body", text: "Great post!")
    end

    it "Indents a reply under its parent comment" do
      post   = create(:blog_post, user: owner)
      parent = create(:comment, commentable: post, user: owner, body: "Parent")
      create(:comment, commentable: post, user: owner, parent: parent, body: "A reply")

      render_pdf(post)

      expect(rendered).to have_css(".pdf-comment--reply .pdf-comment__body", text: "A reply")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Renders a '0 comments' heading and no comment rows when there are none" do
      post = create(:blog_post, user: owner)

      render_pdf(post)

      expect(rendered).to have_css(".pdf-comments__heading", text: "0 comments")
      expect(rendered).to have_no_css(".pdf-comment")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Rewrites a relative ActiveStorage body image into a base64 data URI" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "inline.jpg",
        content_type: "image/jpeg"
      )
      post = create(:blog_post, user: owner,
        body: "![Inline](/rails/active_storage/blobs/#{blob.signed_id}/inline.jpg)")

      render_pdf(post)

      expect(rendered).to have_css(".pdf-body img[src^='data:image/jpeg;base64,']")
      expect(rendered).not_to include("/rails/active_storage/blobs/")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Does not blow up rendering a post with no comments and no reactions" do
      post = create(:blog_post, user: owner)

      expect { render_pdf(post) }.not_to raise_error
    end
  end
end
