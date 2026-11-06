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

    it "Loads the Dossier Timeline without N+1 queries" do
      2.times do
        engagement = create(:dossier_engagement, user: adam)
        create_list(:dossier_assignment, 2, engagement: engagement)
      end

      without_n_plus_one_queries { get dossier_engagements_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads an Assignment's Achievements and their Skills without N+1 queries" do
      assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam),
                                               test_tools_na: false, test_tools_text: "Jira")
      create(:dossier_achievement, assignment: assignment, skills_text: "Jira, Excel")
      create(:dossier_achievement, assignment: assignment, skills_text: "Selenium")

      without_n_plus_one_queries { get dossier_assignment_path(assignment) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads the Achievements page without N+1 queries" do
      2.times do
        assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam))
        create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
        create(:dossier_achievement, assignment: assignment, skills_text: "Excel")
      end

      without_n_plus_one_queries { get dossier_achievements_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Deleted Achievements without N+1 queries" do
      2.times do
        assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam))
        create(:dossier_achievement, assignment: assignment).soft_delete!
      end

      without_n_plus_one_queries { get deleted_dossier_achievements_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads My Career › Skills without N+1 queries" do
      2.times do
        assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam),
                                                 test_tools_na: false, test_tools_text: "Jira, Excel")
        create(:dossier_achievement, assignment: assignment, skills_text: "Selenium")
      end

      without_n_plus_one_queries { get dossier_my_skills_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Skill page with your experience without N+1 queries" do
      2.times do
        assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam),
                                                 test_tools_na: false, test_tools_text: "Jira")
        create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
        create(:dossier_credential, user: adam, provider: create(:dossier_organisation), assignment: assignment,
                                    skills_text: "Jira")
      end

      without_n_plus_one_queries { get dossier_skill_path(Dossier::Skill.find_by!(name: "Jira")) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads My Career › Credentials without N+1 queries" do
      2.times do
        assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam))
        create(:dossier_credential, user: adam, provider: create(:dossier_organisation), assignment: assignment,
                                    skills_text: "Jira, Excel")
        create(:dossier_credential, user: adam, engagement: create(:dossier_engagement, user: adam), skills_text: "Scrum")
        create(:dossier_credential, :certification, user: adam, provider: create(:dossier_organisation))
      end

      without_n_plus_one_queries { get dossier_credentials_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads My Career › Experience without N+1 queries" do
      2.times do
        engagement = create(:dossier_engagement, user: adam, start_month: "2015-01", end_month: "2022-12")
        2.times do
          create(:dossier_assignment, engagement: engagement, client: create(:dossier_organisation, industry: create(:dossier_industry)),
                                      start_month: "2016-01", end_month: "2016-12")
        end
      end

      without_n_plus_one_queries { get dossier_experience_path }

      expect(response).to have_http_status(:ok)
    end

    it "Loads Download Master CV and its Word and PDF downloads without N+1 queries" do
      create(:dossier_profile, user: adam, location: create(:dossier_location))
      2.times do
        engagement = create(:dossier_engagement, user: adam, start_month: "2015-01", end_month: "2022-12")
        2.times do
          assignment = create(:dossier_assignment, engagement: engagement, location: create(:dossier_location),
                                                   start_month: "2016-01", end_month: "2016-12",
                                                   test_tools_na: false, test_tools_text: "Jira, Excel")
          create_list(:dossier_achievement, 2, assignment: assignment, skills_text: "Selenium")
        end
        create(:dossier_credential, :certification, user: adam, provider: create(:dossier_organisation))
        create(:dossier_credential, user: adam, provider: create(:dossier_organisation))
      end

      [ dossier_master_cv_path, docx_dossier_master_cv_path, pdf_dossier_master_cv_path ].each do |path|
        without_n_plus_one_queries { get path }
        expect(response).to have_http_status(:ok)
      end
    end

    it "Loads a CV Variant, its Edit Selection and its downloads without N+1 queries" do
      create(:dossier_profile, user: adam)
      variant = create(:dossier_cv_variant, user: adam, show_tech_stack: true)
      2.times do |n|
        engagement = create(:dossier_engagement, user: adam, start_month: "20#{10 + (n * 8)}-01", end_month: "20#{14 + (n * 8)}-12")
        2.times do
          assignment = create(:dossier_assignment, engagement: engagement, location: create(:dossier_location),
                                                   start_month: "20#{10 + (n * 8)}-01", end_month: "20#{11 + (n * 8)}-12",
                                                   test_tools_na: false, test_tools_text: "Jira, Excel")
          create_list(:dossier_achievement, 2, assignment: assignment, skills_text: "Selenium")
          variant.items.create!(item: assignment, included: true)
        end
        create(:dossier_credential, :certification, user: adam, provider: create(:dossier_organisation))
        create(:dossier_credential, user: adam, provider: create(:dossier_organisation))
      end
      create(:dossier_cv_variant, user: adam)

      [ dossier_cv_variants_path, dossier_cv_variant_path(variant), selection_dossier_cv_variant_path(variant),
        docx_dossier_cv_variant_path(variant), pdf_dossier_cv_variant_path(variant) ].each do |path|
        without_n_plus_one_queries { get path }
        expect(response).to have_http_status(:ok)
      end
    end

    it "Loads an Assignment's Colleagues, Vendors, Customers and their Staff without N+1 queries" do
      assignment = create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam),
                                               test_tools_na: false, test_tools_text: "Jira")
      create(:dossier_achievement, assignment: assignment, skills_text: "Jira")
      create_list(:dossier_colleague, 2, assignment: assignment)
      create_list(:dossier_assignment_partner, 2, assignment: assignment)
        .each { |vendor| create_list(:dossier_staff_member, 2, assignment_partner: vendor) }
      create_list(:dossier_assignment_partner, 2, :customer, assignment: assignment)
        .each { |customer| create(:dossier_staff_member, assignment_partner: customer) }

      without_n_plus_one_queries { get dossier_assignment_path(assignment) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads an Organisation's Vendor and Customer Assignments without N+1 queries" do
      pwc = create(:dossier_organisation, name: "PwC")
      engagement = create(:dossier_engagement, user: adam)
      2.times do
        create(:dossier_assignment_partner, organisation: pwc, assignment: create(:dossier_assignment, engagement: engagement))
        create(:dossier_assignment_partner, :customer, organisation: pwc,
                                                       assignment: create(:dossier_assignment, engagement: engagement))
      end

      without_n_plus_one_queries { get dossier_organisation_path(pwc) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads a Skill Category's Skills, their versions and your years without N+1 queries" do
      databases = create(:dossier_skill_category, name: "Databases")
      oracle = create(:dossier_skill, name: "Oracle", skill_category: databases)
      create_list(:dossier_skill, 2, skill_category: databases, parent: oracle)
      create(:dossier_assignment, engagement: create(:dossier_engagement, user: adam),
                                  other_tools_na: false, other_tools_text: oracle.versions.map(&:name).join(", "))

      without_n_plus_one_queries { get dossier_skill_category_path(databases) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads an Organisation's Credentials without N+1 queries" do
      ni = create(:dossier_organisation, name: "National Instruments")
      create_list(:dossier_credential, 2, user: adam, provider: ni)

      without_n_plus_one_queries { get dossier_organisation_path(ni) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads an Engagement page with its Assignments without N+1 queries" do
      engagement = create(:dossier_engagement, user: adam, start_month: "2019-01", end_month: "2022-12")
      create(:dossier_assignment, engagement: engagement, start_month: "2019-01", end_month: "2019-12")
      create(:dossier_assignment, engagement: engagement, start_month: "2021-01", end_month: "2022-12")

      without_n_plus_one_queries { get dossier_engagement_path(engagement) }

      expect(response).to have_http_status(:ok)
    end

    it "Loads an Engagement's Training without N+1 queries" do
      engagement = create(:dossier_engagement, user: adam)
      create_list(:dossier_credential, 2, user: adam, engagement: engagement, provider: create(:dossier_organisation))

      without_n_plus_one_queries { get dossier_engagement_path(engagement) }

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

    it "Loads the Dossier Timeline without N+1 queries when Assignments have no Role" do
      2.times do
        engagement = create(:dossier_engagement, user: adam)
        create_list(:dossier_assignment, 2, engagement: engagement, role: nil)
      end
      sign_in_as(adam)

      without_n_plus_one_queries { get dossier_engagements_path }

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
