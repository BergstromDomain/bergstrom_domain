# spec/helpers/blog_posts_helper_spec.rb
require "rails_helper"

RSpec.describe BlogPostsHelper, type: :helper do
  def attach_test_image(post)
    post.blog_image.attach(
      io:           File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
      filename:     "test_image.jpg",
      content_type: "image/jpeg"
    )
    post.blog_image.blob
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    describe "#blog_image_data_uri" do
      it "Inlines the attached blog image as a base64 data URI" do
        post = create(:blog_post)
        blob = attach_test_image(post)

        expect(helper.blog_image_data_uri(post)).to eq("data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}")
      end
    end

    describe "#inline_body_images" do
      it "Rewrites a relative ActiveStorage blob img src into a base64 data URI" do
        post = create(:blog_post)
        blob = attach_test_image(post)
        html = %(<p>Text</p><img src="/rails/active_storage/blobs/#{blob.signed_id}/test_image.jpg" alt="x">)

        result = helper.inline_body_images(html)

        expect(result).to include("data:#{blob.content_type};base64,")
        expect(result).not_to include("/rails/active_storage/blobs/")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    describe "#blog_image_data_uri" do
      it "Returns nil when no blog image is attached" do
        post = create(:blog_post)

        expect(helper.blog_image_data_uri(post)).to be_nil
      end
    end

    describe "#inline_body_images" do
      it "Leaves an img src pointing at an unresolvable signed id untouched" do
        html = %(<img src="/rails/active_storage/blobs/not-a-real-signed-id/photo.png">)

        expect(helper.inline_body_images(html)).to include('src="/rails/active_storage/blobs/not-a-real-signed-id/photo.png"')
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    describe "#inline_body_images" do
      it "Leaves an already-inlined base64 data URI untouched" do
        html = %(<img src="data:image/png;base64,abc123">)

        expect(helper.inline_body_images(html)).to include('src="data:image/png;base64,abc123"')
      end

      it "Leaves an img with no src untouched" do
        html = %(<img alt="no src">)

        expect { helper.inline_body_images(html) }.not_to raise_error
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    describe "#inline_body_images" do
      it "Returns the HTML unchanged when there are no img tags at all" do
        html = "<p>Just text, no images</p>"

        expect(helper.inline_body_images(html)).to include("Just text, no images")
      end

      it "Returns an empty string for blank input without raising" do
        expect(helper.inline_body_images("")).to eq("")
      end
    end
  end
end
