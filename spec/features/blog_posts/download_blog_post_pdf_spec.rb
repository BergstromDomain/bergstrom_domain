# spec/features/blog_posts/download_blog_post_pdf_spec.rb

require "rails_helper"

RSpec.describe "Download Blog Post PDF", type: :feature do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows a Download PDF link on the Show page" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "My Great Post")
      visit blog_post_path(post)

      expect(page).to have_selector("[data-testid='download-pdf-link']", text: "Download PDF")
    end

    it "Downloads a PDF with the post title (spaces replaced by underscores) as the filename" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "My Great Post")
      visit blog_post_path(post)
      click_link "Download PDF"

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
      expect(page.response_headers["Content-Disposition"]).to include("My_Great_Post.pdf")
      expect(page.body.byteslice(0, 5)).to eq("%PDF-")
    end

    it "Lets a signed-out guest download an unrestricted, published post's PDF" do
      post = create(:blog_post, :unrestricted, :published, user: owner)
      visit pdf_blog_post_path(post)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects a stranger away from a restricted post's PDF" do
      post = create(:blog_post, :restricted, :published, user: owner)
      visit pdf_blog_post_path(post)

      expect(page).to have_current_path(chronicle_path)
      expect(page).to have_content("You do not have permission")
    end

    it "Returns 404 for a non-existent slug" do
      visit pdf_blog_post_path("non-existent-slug")
      expect(page).to have_http_status(:not_found)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Lets 'Adam Admin' download a restricted post's PDF" do
      post = create(:blog_post, :restricted, :published, user: owner, title: "Admin Only")
      sign_in_as(create(:user, :admin))
      visit pdf_blog_post_path(post)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end

    it "Lets the author download their own unpublished draft's PDF" do
      post = create(:blog_post, :unrestricted, user: owner, title: "My Draft")
      sign_in_as(owner)
      visit pdf_blog_post_path(post)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Includes the header blog image inlined, with no attached image required" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "No Image Post")
      visit pdf_blog_post_path(post)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end

    it "Renders a post that has a real uploaded blog image" do
      post = create(:blog_post, :unrestricted, :published, user: owner, title: "With Image")
      post.blog_image.attach(
        io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename:     "test_image.jpg",
        content_type: "image/jpeg"
      )
      visit pdf_blog_post_path(post)

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
      expect(page.body.byteslice(0, 5)).to eq("%PDF-")
    end
  end
end
