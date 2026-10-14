# spec/requests/guide_images_spec.rb
require "rails_helper"

RSpec.describe "Guide Images", type: :request do
  let(:image) { Rails.root.join("docs/user-guide/cookbook/images/recipe_header.png") }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Serves a User Guide image without signing in" do
      get guide_image_path(app: "cookbook", name: "recipe_header")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.body.b).to eq(image.binread)
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Returns Not Found for an image that doesn't exist" do
      get guide_image_path(app: "cookbook", name: "no_such_image")

      expect(response).to have_http_status(:not_found)
    end

    it "Returns Not Found for an app without a User Guide folder" do
      get guide_image_path(app: "gallery", name: "recipe_header")

      expect(response).to have_http_status(:not_found)
    end

    it "Doesn't serve files outside the images folders" do
      get "/user-guide/images/cookbook/..%2F01_cookbook_overview.png"
      expect(response).to have_http_status(:not_found)

      get "/user-guide/images/cookbook/01_cookbook_overview.md"
      expect(response).to have_http_status(:not_found)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Lets browsers cache the image and answers a repeat request with Not Modified" do
      get guide_image_path(app: "cookbook", name: "recipe_header")
      expect(response.headers["Cache-Control"]).to include("public")

      get guide_image_path(app: "cookbook", name: "recipe_header"),
        headers: { "If-None-Match" => response.headers["ETag"] }

      expect(response).to have_http_status(:not_modified)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Only serves PNGs" do
      get "/user-guide/images/cookbook/recipe_header.jpg"

      expect(response).to have_http_status(:not_found)
    end
  end
end
