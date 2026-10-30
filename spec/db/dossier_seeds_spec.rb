# spec/db/dossier_seeds_spec.rb

require "rails_helper"

RSpec.describe "db/seeds/dossier.rb" do
  def load_seeds = load Rails.root.join("db/seeds/dossier.rb")

  def counts
    [ Dossier::EmploymentType, Dossier::Industry, Dossier::Location, Dossier::Role, Dossier::SkillCategory ].map(&:count)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates the starting Employment Types, Industries, Locations, Roles and Skill Categories" do
      load_seeds
      expect(counts).to eq([ 4, 4, 3, 9, 1 ])
      expect(Dossier::Location.find_by!(city: "Brisbane")).to have_attributes(country: "Australia")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Does not overwrite a row an admin has since edited" do
      create(:dossier_role, name: "Test Manager", description: "Edited by hand")
      load_seeds
      expect(Dossier::Role.find_by!(name: "Test Manager").description).to eq("Edited by hand")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is safe to run twice" do
      load_seeds
      expect { load_seeds }.not_to change { counts }
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Marks only Permanent Employment as permanent" do
      load_seeds
      expect(Dossier::EmploymentType.where(permanent: true).pluck(:name)).to eq([ "Permanent Employment" ])
    end

    it "Includes the Uncategorised Skill Category that imported and on-the-fly Skills start in" do
      load_seeds
      expect(Dossier::SkillCategory.exists?(name: "Uncategorised")).to be(true)
    end
  end
end
