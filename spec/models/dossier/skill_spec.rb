# spec/models/dossier/skill_spec.rb
require "rails_helper"

RSpec.describe Dossier::Skill, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:skill_category_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:aliases).of_type(:string).with_options(array: true, null: false, default: []) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
    it { is_expected.to have_db_column(:parent_id).of_type(:integer) }
    it { is_expected.to have_db_column(:vendor_id).of_type(:integer) }
    it { is_expected.to have_db_column(:show_vendor_in_name).of_type(:boolean).with_options(null: false, default: false) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to belong_to(:skill_category) }
    it { is_expected.to belong_to(:parent).optional }
    it { is_expected.to have_many(:versions).dependent(:nullify) }
    it { is_expected.to belong_to(:vendor).class_name("Dossier::Organisation").optional }
  end

  it_behaves_like "Dossier named reference data", :dossier_skill

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Shows the vendor's name before its own when asked" do
      microsoft = create(:dossier_organisation, name: "Microsoft")
      skill = create(:dossier_skill, name: "Project", vendor: microsoft, show_vendor_in_name: true)

      expect(skill.display_name).to eq("Microsoft Project")
      expect(skill.to_toast_label).to eq("Microsoft Project")
    end

    it "Uses the vendor's abbreviation when it has one" do
      aws = create(:dossier_organisation, name: "Amazon Web Services", abbreviation: "AWS")

      expect(build(:dossier_skill, name: "S3", vendor: aws, show_vendor_in_name: true).display_name).to eq("AWS S3")
    end

    it "Gives a version a slug starting with its parent's name, its old slug still finding it" do
      windows = create(:dossier_skill, name: "Windows")
      xp = create(:dossier_skill, name: "XP")
      old_slug = xp.slug

      xp.update!(parent: windows)

      expect(xp.slug).to eq("windows-xp")
      expect(described_class.friendly.find(old_slug)).to eq(xp)
    end

    it "Takes aliases as comma-separated text" do
      skill = create(:dossier_skill, name: "Selenium", aliases_text: "Selenium WebDriver, WebDriver")
      expect(skill.aliases).to eq([ "Selenium WebDriver", "WebDriver" ])
      expect(skill.aliases_text).to eq("Selenium WebDriver, WebDriver")
    end

    it "Is found by name or alias, ignoring case" do
      skill = create(:dossier_skill, name: "Selenium", aliases_text: "Selenium WebDriver")
      expect(described_class.find_by_name_or_alias("selenium webdriver")).to eq(skill)
      expect(described_class.find_by_name_or_alias("SELENIUM")).to eq(skill)
    end

    it "Is a version of another Skill, labelled by what follows that Skill's name" do
      windows = create(:dossier_skill, name: "Windows")
      xp = create(:dossier_skill, name: "Windows XP", parent: windows)
      ubuntu = create(:dossier_skill, name: "Ubuntu", parent: create(:dossier_skill, name: "Linux"))

      expect(windows.versions).to eq([ xp ])
      expect(xp.version_label).to eq("XP")
      expect(ubuntu.version_label).to eq("Ubuntu")
      expect(xp.family_root).to eq(windows)
      expect(windows.family_root).to eq(windows)
    end

    it "Merges into another Skill: links move, its names become aliases, it's deleted" do
      ec = create(:dossier_skill, name: "Energy Components", aliases_text: "EC")
      old = create(:dossier_skill, name: "Energy Component", aliases_text: "EC Upgrade")
      assignment = create(:dossier_assignment, other_tools_na: false, other_tools_text: "Energy Component")
      achievement = create(:dossier_achievement, skills_text: "Energy Component")
      training = create(:dossier_credential, skills_text: "Energy Component")

      old.merge_into!(ec)

      expect(described_class.exists?(old.id)).to be(false)
      expect(ec.reload.aliases).to eq([ "EC", "Energy Component", "EC Upgrade" ])
      expect(assignment.reload.other_tools_text).to eq("Energy Components")
      expect(achievement.reload.skills_text).to eq("Energy Components")
      expect(training.reload.skills_text).to eq("Energy Components")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Needs a vendor to show the vendor in its name" do
      skill = build(:dossier_skill, show_vendor_in_name: true)

      expect(skill).not_to be_valid
      expect(skill.errors[:vendor]).to include("must be chosen to show it in the name")
    end

    it "Is invalid without a Skill Category" do
      skill = build(:dossier_skill, skill_category: nil)
      expect(skill).not_to be_valid
      expect(skill.errors[:skill_category]).to include("must exist")
    end

    it "Is invalid when an alias is another Skill's name" do
      create(:dossier_skill, name: "WebDriver")
      skill = build(:dossier_skill, name: "Selenium", aliases_text: "webdriver")
      expect(skill).not_to be_valid
      expect(skill.errors[:aliases]).to include("webdriver is already a Skill")
    end

    it "Is invalid when its name is another Skill's alias" do
      create(:dossier_skill, name: "Selenium", aliases_text: "WebDriver")
      skill = build(:dossier_skill, name: "webdriver")
      expect(skill).not_to be_valid
      expect(skill.errors[:name]).to include("is already an alias of Selenium")
    end

    it "Is only one level deep, and never a version of itself" do
      windows = create(:dossier_skill, name: "Windows")
      xp = create(:dossier_skill, name: "Windows XP", parent: windows)

      expect(build(:dossier_skill, name: "Windows XP SP2", parent: xp)).not_to be_valid
      windows.parent = create(:dossier_skill, name: "Operating System")
      expect(windows).not_to be_valid
      expect(windows.errors[:parent]).to include("can't be set on a Skill that has versions")
      xp.parent = xp
      expect(xp).not_to be_valid
    end

    it "Won't merge into itself" do
      skill = create(:dossier_skill)
      expect { skill.merge_into!(skill) }.to raise_error(ArgumentError, "A Skill can't be merged into itself")
      expect(described_class.exists?(skill.id)).to be(true)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Is valid with no aliases" do
      expect(build(:dossier_skill, aliases_text: "")).to be_valid
    end

    it "Shows its name alone without a vendor, or when not asked to show it" do
      atlassian = create(:dossier_organisation, name: "Atlassian")

      expect(build(:dossier_skill, name: "Jira", vendor: atlassian).display_name).to eq("Jira")
      expect(build(:dossier_skill, name: "Git").display_name).to eq("Git")
    end

    it "Keeps the kept Skill's vendor when merging, or takes the merged one's when it has none" do
      microsoft = create(:dossier_organisation, name: "Microsoft")
      oracle = create(:dossier_organisation, name: "Oracle")
      kept = create(:dossier_skill, vendor: oracle)
      create(:dossier_skill, vendor: microsoft).merge_into!(kept)
      expect(kept.reload.vendor).to eq(oracle)

      bare = create(:dossier_skill)
      create(:dossier_skill, vendor: microsoft, show_vendor_in_name: true).merge_into!(bare)
      expect(bare.reload).to have_attributes(vendor: microsoft, show_vendor_in_name: true)
    end

    it "Doesn't repeat the parent's name when the version's name starts with it" do
      ios = create(:dossier_skill, name: "iOS")

      expect(create(:dossier_skill, name: "iOS 3", parent: ios).slug).to eq("ios-3")
    end

    it "Drops the parent's name from its slug when it stops being a version" do
      xp = create(:dossier_skill, name: "XP", parent: create(:dossier_skill, name: "Windows"))

      xp.update!(parent: nil)

      expect(xp.slug).to eq("xp")
    end

    it "Preloads the vendor only for Skills that show it in their name" do
      microsoft = create(:dossier_organisation, name: "Microsoft")
      project = create(:dossier_skill, name: "Project", vendor: microsoft, show_vendor_in_name: true)
      excel = create(:dossier_skill, name: "Excel", vendor: microsoft)
      skills = described_class.where(id: [ project.id, excel.id ]).to_a

      expect(described_class.preload_vendors(skills)).to eq(skills)
      expect(skills.find { |skill| skill.name == "Project" }.association(:vendor)).to be_loaded
      expect(skills.find { |skill| skill.name == "Excel" }.association(:vendor)).not_to be_loaded
    end

    it "Keeps its description when the kept Skill has none" do
      kept = create(:dossier_skill, description: nil)
      create(:dossier_skill, description: "A test tool.").merge_into!(kept)
      expect(kept.reload.description).to eq("A test tool.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Drops blank, duplicate and own-name aliases" do
      skill = create(:dossier_skill, name: "Jira", aliases_text: " , JIRA Software, jira software, Jira,")
      expect(skill.aliases).to eq([ "JIRA Software" ])
    end

    it "Drops a link the kept Skill already has when merging, keeping the other lists' links" do
      kept = create(:dossier_skill, name: "Excel")
      old = create(:dossier_skill, name: "MS Excel")
      assignment = create(:dossier_assignment, test_tools_na: false, test_tools_text: "Excel, MS Excel",
                                               other_tools_na: false, other_tools_text: "MS Excel")
      create(:dossier_achievement, assignment: assignment, skills_text: "Excel, MS Excel")

      old.merge_into!(kept)

      expect(assignment.reload.test_tools_text).to eq("Excel")
      expect(assignment.other_tools_text).to eq("Excel")
      expect(Dossier::AchievementSkill.where(skill: kept).count).to eq(1)
    end

    it "Hands its versions to the kept Skill when merged, and frees them when deleted" do
      old = create(:dossier_skill, name: "MS Windows")
      xp = create(:dossier_skill, name: "Windows XP", parent: old)
      windows = create(:dossier_skill, name: "Windows")

      old.merge_into!(windows)
      expect(xp.reload.parent).to eq(windows)
      windows.destroy!
      expect(xp.reload.parent).to be_nil
    end

    it "Gives its versions new slugs when renamed, keeping their old ones" do
      windows = create(:dossier_skill, name: "Windows")
      xp = create(:dossier_skill, name: "XP", parent: windows)

      windows.update!(name: "Microsoft Windows")

      expect(xp.reload.slug).to eq("microsoft-windows-xp")
      expect(described_class.friendly.find("windows-xp")).to eq(xp)
    end

    it "Leaves its versions' slugs alone when only its description changes" do
      windows = create(:dossier_skill, name: "Windows")
      xp = create(:dossier_skill, name: "XP", parent: windows)

      windows.update!(description: "An operating system.")

      expect(xp.reload.slug).to eq("windows-xp")
      expect(xp.slugs.count).to eq(1)
    end

    it "Gives versions handed over in a merge their new parent's name in their slug" do
      old = create(:dossier_skill, name: "MS Windows")
      xp = create(:dossier_skill, name: "XP", parent: old)

      old.merge_into!(create(:dossier_skill, name: "Windows"))

      expect(xp.reload.slug).to eq("windows-xp")
    end

    it "Returns nil for a blank lookup" do
      expect(described_class.find_by_name_or_alias(" ")).to be_nil
    end
  end
end
