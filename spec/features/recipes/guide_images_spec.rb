# spec/features/recipes/guide_images_spec.rb
require "rails_helper"

# Takes the Cookbook User Guide screenshots in docs/user-guide/cookbook/images.
# Skipped unless GUIDE_SCREENSHOTS=1 (see spec/support/guide_images.rb):
#
#   GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/recipes/guide_images_spec.rb
#
# Everything on screen is fixed — names, dates, the photo — so a re-run only
# changes an image when the screen itself has changed.
RSpec.describe "Cookbook Guide Images", type: :feature, js: true, guide_image: true do
  include ActiveSupport::Testing::TimeHelpers

  let!(:charlie) do
    create(:user, :content_creator, first_name: "Charlie", last_name: "Content Creator",
      email_address: "charlie@example.com")
  end

  let!(:english)  { create(:language, name: "English", code: "en", flag: "🇬🇧") }
  let!(:french)   { create(:cuisine, name: "French",  flag: "🇫🇷") }
  let!(:italian)  { create(:cuisine, name: "Italian", flag: "🇮🇹") }
  let!(:swedish)  { create(:cuisine, name: "Swedish", flag: "🇸🇪") }
  let!(:bread)    { create(:food_type, name: "Bread",    icon: "wheat") }
  let!(:desserts) { create(:food_type, name: "Desserts", icon: "cake-slice") }
  let!(:mince)    { create(:food_type, name: "Mince",    icon: "hamburger") }

  let!(:lasagna) do
    create_recipe("Niks Lasagna", cuisines: [ italian ], food_types: [ mince ],
      description: "A family favourite: a slow-cooked meat sauce layered with a creamy cheese sauce.",
      serves: 6, cook_time: "2 hours",
      sections: {
        "Meat sauce"   => [ [ "500", "g", "beef mince" ], [ "1", nil, "onion, finely chopped" ],
                            [ "2", nil, "garlic cloves" ], [ "400", "g", "crushed tomatoes" ] ],
        "Cheese sauce" => [ [ "50", "g", "butter" ], [ "3", "tbsp", "plain flour" ],
                            [ "6", "dl", "milk" ], [ "150", "g", "grated cheese" ] ],
        "Assembly"     => [ [ "12", nil, "lasagne sheets" ] ]
      },
      image: "docs/test-data/images/cookbook/recipes/lasagna.jpeg")
  end

  before do
    travel_to Time.zone.local(2026, 10, 1, 18, 0)
    create_recipe("Swedish Meatballs", cuisines: [ swedish ], food_types: [ mince ])
    create_recipe("Kanelbullar", cuisines: [ swedish ], food_types: [ bread ])
    create_recipe("Tiramisu", cuisines: [ italian ], food_types: [ desserts ])
    create_recipe("Crêpes", cuisines: [ french ], food_types: [ desserts ])
  end

  def create_recipe(title, cuisines:, food_types:, sections: { nil => [ [ "1", nil, "egg" ] ] },
                    description: nil, serves: 4, cook_time: "1 hour", image: nil)
    recipe = build(:recipe, :unrestricted, title: title, user: charlie, language: english,
      cuisines: cuisines, food_types: food_types, description: description, serves: serves,
      cook_time: cook_time, published_at: Time.current,
      body: "1. Prepare the ingredients.\n2. Cook.\n3. Serve.")
    sections.each_with_index do |(heading, rows), section_position|
      section = recipe.ingredient_sections.build(heading: heading, position: section_position)
      rows.each_with_index do |(quantity, measurement, name), position|
        section.ingredients.build(quantity: quantity, measurement: measurement, name: name, position: position)
      end
    end
    recipe.recipe_image.attach(io: File.open(Rails.root.join(image)), filename: File.basename(image)) if image
    recipe.save!
    recipe
  end

  it "Captures the recipe page" do
    visit recipe_path(lasagna)
    expect(page).to have_css("[data-testid='recipe-image'] img")

    capture_guide_image("recipe-header", as: "cookbook/recipe_header")
    capture_guide_image("show-panel-metadata", as: "cookbook/recipe_details")
    capture_guide_image("recipe-ingredients", as: "cookbook/recipe_ingredients")
  end

  it "Captures the Write A Recipe form" do
    sign_in_as(charlie)
    expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    visit edit_recipe_path(lasagna)

    capture_guide_image("new-panel-title", as: "cookbook/recipe_form_title")
    capture_guide_image("new-panel-metadata", as: "cookbook/recipe_form_details")
    capture_guide_image("new-panel-ingredients", as: "cookbook/recipe_form_ingredients")
  end

  it "Captures Browse Recipes By Cuisine" do
    visit browse_by_cuisine_recipes_path

    capture_guide_image("browse-tree", as: "cookbook/browse_by_cuisine")
  end

  it "Captures the Filter Recipes panel" do
    visit filter_recipes_path

    capture_guide_image("basic-panel", as: "cookbook/filter_basic")
  end

  it "Captures the Cookbook left nav" do
    sign_in_as(charlie)
    expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
    visit cookbook_path
    # .left-nav is 100vh tall but starts below the top bar, so its last links
    # sit behind the footer — let it take its natural height for the image.
    page.execute_script("document.querySelector('[data-testid=\"left-nav\"]').style.height = 'auto'")

    capture_guide_image("left-nav", as: "cookbook/left_nav")
  end
end
