# spec/features/dossier/guide_images_spec.rb
require "rails_helper"

# Takes the Dossier User Guide screenshots in docs/user-guide/dossier/images,
# in the story world (spec/support/guide_story_world.rb): Charlie's career as
# a research assistant and then a physics teacher, filled out here with a
# Profile, Roles, Achievements, a Tech Stack, Credentials and a CV Variant.
# Everything is fictional. Skipped unless GUIDE_SCREENSHOTS=1 (see
# spec/support/guide_images.rb):
#
#   GUIDE_SCREENSHOTS=1 bundle exec rspec spec/features/dossier/guide_images_spec.rb
RSpec.describe "Dossier Guide Images", type: :feature, js: true, guide_image: true do
  include ActiveSupport::Testing::TimeHelpers

  # Before the world is built (let! is a before hook too), so its dates are fixed.
  before { travel_to GuideStoryWorld::STORY_TIME }
  after  { travel_back }

  let!(:world) { build_story_world }
  let(:school)      { world.engagements[:school].assignments.first }
  let(:observatory) { world.engagements[:observatory].assignments.first }

  before do
    fill_in_charlies_career
    sign_in_as(world.charlie)
    expect(page).to have_css("[data-testid='user-thumbnail-dropdown']", wait: 8)
  end

  def fill_in_charlies_career
    grantham = create(:dossier_location, city: "Grantham", country: "England")
    world.charlie.dossier_profile.update!(headline: "Physics Teacher | Former Research Assistant",
      location: grantham, email: "charlie@example.com",
      summary: "Physics teacher who turns lessons into experiments.",
      summary_first_person: "I'm a physics teacher who turns lessons into experiments.")

    teaching = create(:dossier_skill_category, name: "Teaching Methods")
    software = create(:dossier_skill_category, name: "Software")
    Dossier::Skill.find_by!(name: "Inquiry-Based Learning").update!(skill_category: teaching)
    %w[Python Excel].each { |name| create(:dossier_skill, name: name, skill_category: software) }
    world.engagements[:school].employer.update!(industry: create(:dossier_industry, name: "Education"))
    world.engagements[:observatory].employer.update!(industry: create(:dossier_industry, name: "Research"))

    school.update!(role: create(:dossier_role, name: "Teacher"), location: grantham)
    observatory.update!(role: create(:dossier_role, name: "Research Assistant"),
      location: create(:dossier_location, city: "London", country: "England"),
      other_tools_na: false, other_tools_text: "Python, Excel")

    create(:dossier_achievement, assignment: school, text: "Raised the Year 12 physics pass rate",
      impact: "from 72% to 91%", importance: 5, skills_text: "Inquiry-Based Learning")
    create(:dossier_achievement, assignment: school, text: "Started an after-school astronomy club", importance: 3)
    create(:dossier_achievement, assignment: observatory, text: "Catalogued 4,000 stars for the Star Catalogue",
      importance: 4, skills_text: "Python")

    degree = Dossier::CredentialType.create!(name: "Degree", position: 1)
    create(:dossier_credential, user: world.charlie, credential_type: degree, title: "BSc Physics",
      provider: create(:dossier_organisation, name: "University of Cambridge"),
      start_on: Date.new(2012, 10, 1), end_on: Date.new(2015, 6, 1))
    create(:dossier_credential, user: world.charlie, title: "Teaching Physics Through Experiments", hours: 6,
      engagement: world.engagements[:school], start_on: Date.new(2020, 2, 1), end_on: Date.new(2020, 2, 1))
    Dossier::CredentialType.find_by!(name: "Course").update!(position: 4) # as seeded: after Degree

    create(:dossier_cv_variant, user: world.charlie, name: "Head of Physics — Grantham College",
      target_company: "Grantham College", target_role: "Head of Physics", voice: "first_person")
  end

  # The main area stretches to the window's height; shrink it to its content
  # so an index page's screenshot ends where the page does.
  def capture_main_content(as:)
    page.execute_script("const main = document.querySelector('[data-testid=\"main-content\"]'); " \
                        "main.style.height = 'auto'; main.style.overflowY = 'visible'")
    capture_guide_image("main-content", as: as)
  end

  it "Captures the Profile, an Engagement form and an Assignment's page" do
    visit dossier_engagements_path
    capture_guide_image("timeline", as: "dossier/timeline")

    visit dossier_profile_path
    capture_guide_image(%w[show-panel-main show-panel-metadata], as: "dossier/profile")

    visit new_dossier_engagement_path
    capture_guide_image(%w[new-panel-main new-panel-dates], as: "dossier/engagement_form")

    visit dossier_assignment_path(school)
    capture_guide_image(%w[show-panel-metadata tech-stack], as: "dossier/assignment_page")
    capture_guide_image("assignment-achievements", as: "dossier/assignment_achievements")
  end

  it "Captures Achievements, Skills and Experience" do
    visit dossier_achievements_path
    capture_main_content(as: "dossier/achievements")

    visit new_dossier_achievement_path
    capture_guide_image(%w[new-panel-main new-panel-details], as: "dossier/achievement_form")

    visit dossier_my_skills_path
    capture_main_content(as: "dossier/my_skills")

    visit dossier_skill_path(Dossier::Skill.find_by!(name: "Python"))
    capture_guide_image("skill-experience", as: "dossier/skill_experience")

    visit dossier_experience_path
    capture_main_content(as: "dossier/experience")
  end

  it "Captures Credentials" do
    visit dossier_credentials_path
    capture_main_content(as: "dossier/credentials")
  end

  it "Captures a CV Variant, its selection, and Download Master CV" do
    variant = Dossier::CvVariant.find_by!(name: "Head of Physics — Grantham College")
    visit dossier_cv_variant_path(variant)
    capture_guide_image(%w[show-panel-metadata show-panel-actions], as: "dossier/cv_variant")

    visit selection_dossier_cv_variant_path(variant)
    capture_guide_image(%w[selection-experience selection-actions], as: "dossier/cv_variant_selection")

    visit dossier_master_cv_path
    capture_guide_image("master-cv-panel", as: "dossier/master_cv")

    visit new_dossier_import_path
    capture_guide_image("import-panel", as: "dossier/import")
  end
end
