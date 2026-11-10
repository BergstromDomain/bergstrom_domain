# spec/requests/dossier/courses_spec.rb
require "rails_helper"

# Browse and Filter Courses: the signed-in Content Creator's own Courses.
RSpec.describe "Dossier Courses", type: :request do
  let(:charlie) { create(:user, :content_creator) }
  let(:uno)     { create(:user) }
  let(:provider) { create(:dossier_organisation, name: "LinkedIn Learning") }

  def course(**attributes) = create(:dossier_credential, user: charlie, provider: provider, **attributes)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Filters by Skill, year completed and words in the title" do
      course(title: "Learning Docker", skills_text: "Docker", end_on: Date.new(2022, 5, 1), start_on: Date.new(2022, 5, 1))
      course(title: "Learning Chef", skills_text: "Chef", end_on: Date.new(2021, 5, 1), start_on: Date.new(2021, 5, 1))
      sign_in_as(charlie)

      get dossier_filter_courses_path(skill_id: Dossier::Skill.find_by!(name: "Docker").id)
      expect(response.body).to include("Learning Docker")
      expect(response.body).not_to include("Learning Chef")
      get dossier_filter_courses_path(year: "2021")
      expect(response.body).to include("Learning Chef")
      expect(response.body).not_to include("Learning Docker")
      get dossier_filter_courses_path(q: "dock")
      expect(response.body).to include("Learning Docker")
      expect(response.body).not_to include("Learning Chef")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Refuses an App User" do
      sign_in_as(uno)

      [ dossier_browse_courses_path, dossier_filter_courses_path ].each do |path|
        get path
        expect(response).to redirect_to(dossier_path)
        expect(flash[:alert]).to eq("Not authorised.")
      end
    end

    it "Leaves Certifications and Degrees out" do
      create(:dossier_credential, :certification, user: charlie, title: "ICAgile Certified Professional", provider: provider)
      sign_in_as(charlie)

      get dossier_filter_courses_path
      expect(response.body).not_to include("ICAgile Certified Professional")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Ignores an unknown provider, status or year" do
      course(title: "Learning Docker")
      sign_in_as(charlie)

      get dossier_filter_courses_path(provider_id: "nobody", status: "abandoned", year: "20x2")
      expect(response.body).to include("Learning Docker")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Sends a Browse URL naming an unknown provider back to the Browse root" do
      sign_in_as(charlie)

      get dossier_browse_courses_path(provider_id: "nobody")
      expect(response).to redirect_to(dossier_browse_courses_path)
    end

    it "Treats a % in the title search as a literal" do
      course(title: "Learning Docker")
      sign_in_as(charlie)

      get dossier_filter_courses_path(q: "%")
      expect(response.body).to include("No Courses match these filters.")
    end
  end
end
