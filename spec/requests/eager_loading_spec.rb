# spec/requests/eager_loading_spec.rb

require "rails_helper"

# List pages that render one row/card per record must eager-load everything
# each row touches — Bullet (dev only) flagged these as N+1s during manual
# testing. Two records per page is the minimum Bullet needs to spot one.
RSpec.describe "Eager loading", type: :request do
  let(:adam) { create(:user, :admin) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    before { sign_in_as(adam) }

    it "Loads Filter Blog Posts without N+1 queries" do
      create_list(:blog_post, 2)

      without_n_plus_one_queries { get filter_blog_posts_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Browse Blog Posts preview panel without N+1 queries" do
      category = create(:blog_category)
      create_list(:blog_post, 2, blog_category: category)

      without_n_plus_one_queries { get blog_posts_path(category_id: category.slug) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Filter Recipes without N+1 queries" do
      create_list(:recipe, 2, :published, cuisines: create_list(:cuisine, 2))

      without_n_plus_one_queries { get filter_recipes_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Filter Recipes SQL query on Language and ingredients without N+1 queries" do
      create_list(:recipe, 2, :published)

      without_n_plus_one_queries do
        get filter_recipes_path(mode: "sql", query: 'language != "x" AND ingredients CONTAINS "onion"', sort: "chef")
      end

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Browse Recipes By Cuisine preview panel without N+1 queries" do
      cuisine = create(:cuisine)
      create_list(:recipe, 2, :published, cuisines: [ cuisine, create(:cuisine) ])

      without_n_plus_one_queries { get browse_by_cuisine_recipes_path(cuisine_id: cuisine.slug) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Find Recipes By Ingredients without N+1 queries" do
      2.times do
        create(:recipe, :published, cuisines: create_list(:cuisine, 2),
          ingredient_sections_attributes: { "0" => { ingredients_attributes: {
            "0" => { quantity: "1", name: "Garlic" }, "1" => { quantity: "1", name: "Cream" } } } })
      end

      without_n_plus_one_queries { get find_by_ingredients_recipes_path(ingredients: [ "garlic", "cream" ]) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads and saves the Edit A Recipe form without N+1 queries" do
      cuisines   = create_list(:cuisine, 2)
      food_types = create_list(:food_type, 2)
      recipe = create(:recipe, user: adam, cuisines: cuisines, food_types: food_types, ingredient_sections_attributes: {
        "0" => { heading: "Sauce",   ingredients_attributes: { "0" => { quantity: "1", name: "Butter" } } },
        "1" => { heading: "Topping", ingredients_attributes: { "0" => { quantity: "1", name: "Cheese" } } }
      })
      choices = { cuisine_ids: cuisines.reverse.map(&:id), food_type_ids: food_types.reverse.map(&:id) }

      without_n_plus_one_queries { get edit_recipe_path(recipe) }
      expect(response).to have_http_status(:ok)

      without_n_plus_one_queries { patch recipe_path(recipe), params: { recipe: choices.merge(title: "") } }
      expect(response).to have_http_status(:unprocessable_entity)

      without_n_plus_one_queries { patch recipe_path(recipe), params: { recipe: choices.merge(title: "Renamed") } }
      expect(response).to redirect_to(recipe_path(recipe.reload))
    end

    it "Loads Filter People and Events without N+1 queries" do
      create_list(:event, 2)

      without_n_plus_one_queries { get filter_people_events_path }

      expect(response).to have_http_status(:ok)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Fails code that does have an N+1 query" do
      create_list(:blog_post, 2)

      expect {
        without_n_plus_one_queries { BlogPost.all.each { |post| post.user.email_address } }
      }.to raise_error(Bullet::Notification::UnoptimizedQueryError)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Loads Download Blog Posts without N+1 or unused eager loading" do
      sign_in_as(adam)
      create_list(:blog_post, 2)

      without_n_plus_one_queries { get blog_exports_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a filtered Download Blog Posts without N+1 queries" do
      sign_in_as(adam)
      create_list(:blog_post, 2, :published)

      without_n_plus_one_queries { get blog_exports_path(published: "published") }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Download Recipes and its CSV and PDF downloads without N+1 or unused eager loading" do
      sign_in_as(adam)
      create_list(:recipe, 2, :published, cuisines: create_list(:cuisine, 2))

      [ recipe_exports_path, csv_recipe_exports_path, pdfs_recipe_exports_path ].each do |path|
        without_n_plus_one_queries { get path }
        expect(response).to have_http_status(:ok)
      end
    end

    it "Loads Download People and Events without N+1 or unused eager loading" do
      sign_in_as(adam)
      create_list(:event, 2)

      without_n_plus_one_queries { get people_events_exports_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Filter Blog Posts without N+1 queries for a guest" do
      create_list(:blog_post, 2, :unrestricted, :published)

      without_n_plus_one_queries { get filter_blog_posts_path }

      expect(response).to have_http_status(:ok)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Leaves Bullet switched off again after the block" do
      without_n_plus_one_queries { nil }

      expect(Bullet.enable?).to be(false)
    end

    it "Loads Filter Recipes without unused eager loading when nothing matches" do
      sign_in_as(adam)
      create_list(:recipe, 2, :published)

      without_n_plus_one_queries { get filter_recipes_path(mode: "sql", query: 'title = "No Such Recipe"') }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Browse Recipes By Cuisine preview panel with recipe images without unused eager loading" do
      sign_in_as(adam)
      cuisine = create(:cuisine)
      create_list(:recipe, 2, :published, cuisines: [ cuisine ]).each do |recipe|
        recipe.recipe_image.attach(io: file_fixture("test_image.jpg").open, filename: "lasagna.jpg")
        recipe.recipe_image.variant(:thumbnail).processed
      end

      without_n_plus_one_queries { get browse_by_cuisine_recipes_path(cuisine_id: cuisine.slug) }

      expect(response).to have_http_status(:ok)
    end
  end
end
