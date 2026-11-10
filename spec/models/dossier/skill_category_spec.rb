# spec/models/dossier/skill_category_spec.rb
require "rails_helper"

RSpec.describe Dossier::SkillCategory, type: :model do
  # ── Database Columns ──────────────────────────────────────────────────────
  describe "Database Columns" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:slug).of_type(:string) }
    it { is_expected.to have_db_column(:parent_id).of_type(:integer) }
    it { is_expected.to have_db_column(:position).of_type(:integer) }
  end

  # ── Associations ──────────────────────────────────────────────────────────
  describe "Associations" do
    it { is_expected.to have_many(:skills).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:parent).class_name("Dossier::SkillCategory").optional }
    it { is_expected.to have_many(:subcategories).dependent(:restrict_with_error) }

    it "Can't be deleted while a Skill uses it" do
      category = create(:dossier_skill_category)
      create(:dossier_skill, skill_category: category)
      expect(category.destroy).to be(false)
    end
  end

  it "Uses the dossier_ table prefix" do
    expect(described_class.table_name).to eq("dossier_skill_categories")
  end

  it_behaves_like "Dossier named reference data", :dossier_skill_category

  describe "Sub-categories" do
    let(:protocols) { create(:dossier_skill_category, name: "Protocols & Standards") }

    # 1) Happy Path ─────────────────────────────────────────────────────────────
    describe "Happy Path" do
      it "Lists a parent's sub-categories A–Z, and leaves them out of top_level" do
        web = create(:dossier_skill_category, name: "Web", parent: protocols)
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)

        expect(protocols.subcategories).to eq([ voip, web ])
        expect(described_class.top_level).to eq([ protocols ])
      end

      it "Lists sub-categories by position first, then A–Z for those without one" do
        web = create(:dossier_skill_category, name: "Web", parent: protocols, position: 1)
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols, position: 2)
        healthcare = create(:dossier_skill_category, name: "Healthcare", parent: protocols)
        apps = create(:dossier_skill_category, name: "Apps", parent: protocols)

        expect(protocols.subcategories).to eq([ web, voip, apps, healthcare ])
      end

      it "Sorts top-level categories by position, then A–Z for those without one" do
        testing = create(:dossier_skill_category, name: "Testing", position: 1)
        ai = create(:dossier_skill_category, name: "AI Tools", position: 2)
        uncategorised = create(:dossier_skill_category, name: "Uncategorised")

        expect([ uncategorised, protocols, ai, testing ].sort_by(&:display_sort_key)).to eq([ testing, ai, protocols, uncategorised ])
      end

      it "Names a sub-category in full as 'Parent › Sub', a top-level one by its name" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)

        expect(voip.full_name).to eq("Protocols & Standards › VoIP")
        expect(protocols.full_name).to eq("Protocols & Standards")
      end

      it "Lists its own Skills and its sub-categories' Skills together" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        sip = create(:dossier_skill, name: "SIP", skill_category: voip)
        tcp = create(:dossier_skill, name: "TCP/IP", skill_category: protocols)

        expect(protocols.all_skills).to contain_exactly(sip, tcp)
        expect(voip.all_skills).to eq([ sip ])
      end
    end

    # 2) Negative Path ──────────────────────────────────────────────────────────
    describe "Negative Path" do
      it "Won't nest a sub-category under another sub-category" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        tools = build(:dossier_skill_category, name: "SIP Tools", parent: voip)

        expect(tools).not_to be_valid
        expect(tools.errors[:parent]).to include("must be a top-level Skill Category")
      end

      it "Won't give a Parent to a category that has sub-categories" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        protocols.parent = create(:dossier_skill_category, name: "Testing")

        expect(protocols).not_to be_valid
        expect(protocols.errors[:parent]).to include("can't be set while it has sub-categories")
      end

      it "Won't be its own Parent" do
        protocols.parent = protocols

        expect(protocols).not_to be_valid
        expect(protocols.errors[:parent]).to include("can't be itself")
      end

      it "Can't be deleted while it has sub-categories" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)

        expect(protocols.destroy).to be(false)
        expect(protocols.errors.full_messages.join).to match(/sub-categories/i)
      end
    end

    # 3) Alternative Path ───────────────────────────────────────────────────────
    describe "Alternative Path" do
      it "Becomes top-level again when its Parent is cleared" do
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        voip.update!(parent: nil)

        expect(described_class.top_level).to include(voip)
        expect(voip.full_name).to eq("VoIP")
      end

      it "Sorts sub-categories right after their parent" do
        testing = create(:dossier_skill_category, name: "Testing")
        voip = create(:dossier_skill_category, name: "VoIP", parent: protocols)
        ai = create(:dossier_skill_category, name: "AI Tools")

        expect(described_class.in_tree_order).to eq([ ai, protocols, voip, testing ])
      end
    end

    # 4) Edge Cases ─────────────────────────────────────────────────────────────
    describe "Edge Cases" do
      it "Allows the same name under two parents, with distinct slugs" do
        business = create(:dossier_skill_category, name: "Business Applications")
        testing = create(:dossier_skill_category, name: "Testing")
        first = create(:dossier_skill_category, name: "Other", parent: business)
        second = create(:dossier_skill_category, name: "Other", parent: testing)

        expect(first.slug).to eq("other")
        expect(second.slug).to eq("testing-other")
      end

      it "Refuses the same name twice under one parent, ignoring case" do
        create(:dossier_skill_category, name: "VoIP", parent: protocols)
        duplicate = build(:dossier_skill_category, name: "voip", parent: protocols)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("has already been taken")
      end

      it "Allows a sub-category to share a top-level category's name" do
        create(:dossier_skill_category, name: "Other")

        expect(build(:dossier_skill_category, name: "Other", parent: protocols)).to be_valid
      end
    end
  end
end
