# spec/services/dossier/skill_taxonomy_spec.rb
require "rails_helper"

RSpec.describe Dossier::SkillTaxonomy do
  let(:user)       { create(:user, :content_creator) }
  let(:engagement) { create(:dossier_engagement, user: user, start_month: "2015-01", end_month: "2016-12") }

  def apply(taxonomy) = described_class.new(taxonomy.deep_stringify_keys).apply!
  def category(path) = described_class.find_category(path)
  def skill(name) = Dossier::Skill.find_by_name_or_alias(name)

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Renames a category found by an old name, and its slug follows" do
      old = create(:dossier_skill_category, name: "CI/CD")
      apply(categories: [ { name: "Development Tools", was: [ "CI/CD" ] } ])

      expect(old.reload).to have_attributes(name: "Development Tools", slug: "development-tools")
    end

    it "Creates sub-categories under their parent, and moves an old top-level one under it" do
      ides = create(:dossier_skill_category, name: "IDEs & Editors")
      apply(categories: [ { name: "Development Tools",
                            subcategories: [ { name: "Version Control" }, { name: "IDEs & Editors", was: [ "IDEs & Editors" ] } ] } ])

      top = category("Development Tools")
      expect(top.subcategories.map(&:name)).to eq([ "IDEs & Editors", "Version Control" ])
      expect(ides.reload.parent).to eq(top)
    end

    it "Moves an existing Skill found by alias, setting its vendor, aliases, Version Of and description" do
      office = create(:dossier_skill_category, name: "Office & Project")
      project = create(:dossier_skill, name: "Project", aliases_text: "MS Project", skill_category: office)
      apply(vendors: [ { name: "Microsoft" } ],
            categories: [ { name: "Office & Collaboration", was: [ "Office & Project" ] } ],
            skills: [ { name: "Project", find: [ "ms project" ], category: "Office & Collaboration", vendor: "Microsoft",
                        show_vendor: true, aliases: [ "Microsoft Project" ], description: "Plans projects." } ])

      expect(project.reload).to have_attributes(display_name: "Microsoft Project", description: "Plans projects.",
                                                aliases: [ "MS Project", "Microsoft Project" ])
    end

    it "Creates Skills that don't exist yet, as versions where asked" do
      systems = create(:dossier_skill_category, name: "Operating Systems")
      windows = create(:dossier_skill, name: "Windows", skill_category: systems)
      report = apply(categories: [ { name: "Operating Systems" } ],
                     skills: [ { name: "95", category: "Operating Systems", version_of: "Windows", aliases: [ "Windows 95" ] } ])

      expect(skill("Windows 95")).to have_attributes(name: "95", parent: windows, skill_category: systems)
      expect(report).to include("Created Skill 95")
    end

    it "Finds vendors by name or abbreviation, creating missing ones" do
      aws = create(:dossier_organisation, name: "Amazon Web Services", abbreviation: "AWS")
      apply(vendors: [ { name: "AWS" }, { name: "SAP" } ], categories: [ { name: "Cloud Computing" } ],
            skills: [ { name: "S3", category: "Cloud Computing", vendor: "AWS", show_vendor: true } ])

      expect(skill("S3").vendor).to eq(aws)
      expect(Dossier::Organisation.find_by(name: "SAP")).to be_present
    end

    it "Merges listed Skills into the kept one, moving their links" do
      video = create(:dossier_skill_category, name: "Protocols")
      h264 = create(:dossier_skill, name: "H.264", skill_category: video)
      create(:dossier_skill, name: "AVC", skill_category: video)
      assignment = create(:dossier_assignment, engagement: engagement, other_tools_na: false, other_tools_text: "AVC")
      apply(categories: [ { name: "Protocols" } ], merge: [ { into: "H.264", from: [ "AVC", "Not There" ] } ])

      expect(assignment.reload.skills_in(:other_tool)).to eq([ h264 ])
      expect(h264.reload.aliases).to eq([ "AVC" ])
    end

    it "Splits a Skill: every new Skill gets all its links, then it's deleted" do
      cards = create(:dossier_skill_category, name: "Smart Cards")
      create(:dossier_skill, name: "SCP02/SCP80", skill_category: cards)
      assignment = create(:dossier_assignment, engagement: engagement, other_tools_na: false, other_tools_text: "SCP02/SCP80")
      achievement = create(:dossier_achievement, assignment: assignment, skills_text: "SCP02/SCP80")
      apply(categories: [ { name: "Smart Cards" } ],
            skills: [ { name: "SCP02", category: "Smart Cards" }, { name: "SCP80", category: "Smart Cards" } ],
            split: [ { from: "SCP02/SCP80", into: [ "SCP02", "SCP80" ] } ])

      expect(assignment.reload.skills_in(:other_tool).map(&:name)).to contain_exactly("SCP02", "SCP80")
      expect(achievement.reload.current_skills.map(&:name)).to contain_exactly("SCP02", "SCP80")
      expect(Dossier::Skill.find_by(name: "SCP02/SCP80")).to be_nil
    end

    it "Renames a Skill found by an old name, keeping its links" do
      ides = create(:dossier_skill_category, name: "IDEs")
      typo = create(:dossier_skill, name: "DreamWeawer", skill_category: ides)
      apply(categories: [ { name: "IDEs" } ], skills: [ { name: "Dreamweaver", find: [ "DreamWeawer" ], category: "IDEs" } ])

      expect(typo.reload.name).to eq("Dreamweaver")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rolls everything back and names the row when a category is unknown" do
      create(:dossier_skill_category, name: "CI/CD")
      taxonomy = { categories: [ { name: "Development Tools", was: [ "CI/CD" ] } ],
                   skills: [ { name: "Git", category: "Development Tools › Nowhere" } ] }

      expect { apply(taxonomy) }.to raise_error(described_class::Error, /Git: no Skill Category "Development Tools › Nowhere"/)
      expect(Dossier::SkillCategory.pluck(:name)).to eq([ "CI/CD" ])
    end

    describe "White-box: every refused row rolls back and names itself" do
      before { create(:dossier_skill_category, name: "Tools") }

      it "Refuses a Skill whose alias is another Skill's name" do
        create(:dossier_skill, name: "Git", skill_category: Dossier::SkillCategory.first)

        expect { apply(skills: [ { name: "GitHub", category: "Tools", aliases: [ "Git" ] } ]) }
          .to raise_error(described_class::Error, "GitHub: Aliases Git is already a Skill")
      end

      it "Refuses an unknown vendor" do
        expect { apply(skills: [ { name: "Excel", category: "Tools", vendor: "Nobody" } ]) }
          .to raise_error(described_class::Error, 'Excel: no vendor "Nobody"')
      end

      it "Refuses an unknown Skill to be a version of" do
        expect { apply(skills: [ { name: "XP", category: "Tools", version_of: "Windows" } ]) }
          .to raise_error(described_class::Error, 'XP: no Skill "Windows" to be a version of')
        expect(skill("XP")).to be_nil
      end

      it "Refuses a split into a Skill that doesn't exist" do
        create(:dossier_skill, name: "SSH/SCP", skill_category: Dossier::SkillCategory.first)

        expect { apply(split: [ { from: "SSH/SCP", into: [ "SSH" ] } ]) }
          .to raise_error(described_class::Error, 'Split: no Skill "SSH" to split SSH/SCP into')
      end

      it "Refuses a merge into a Skill that doesn't exist" do
        create(:dossier_skill, name: "AVC", skill_category: Dossier::SkillCategory.first)

        expect { apply(merge: [ { into: "H.264", from: [ "AVC" ] } ]) }
          .to raise_error(described_class::Error, 'Merge: no Skill "H.264" to merge AVC into')
      end

      it "Clears a vendor and a Version Of when the row sets them to nothing" do
        tools = Dossier::SkillCategory.first
        windows = create(:dossier_skill, name: "Windows", skill_category: tools)
        xp = create(:dossier_skill, name: "XP", skill_category: tools, parent: windows,
                                    vendor: create(:dossier_organisation, name: "Microsoft"))
        apply(skills: [ { name: "XP", category: "Tools", vendor: nil, version_of: nil } ])

        expect(xp.reload).to have_attributes(vendor: nil, parent: nil)
      end
    end

    it "Keeps and reports a listed Skill that is still used" do
      tools = create(:dossier_skill_category, name: "Tools")
      create(:dossier_skill, name: "Leftover", skill_category: tools)
      create(:dossier_assignment, engagement: engagement, other_tools_na: false, other_tools_text: "Leftover")
      report = apply(delete_skills: [ "Leftover" ])

      expect(skill("Leftover")).to be_present
      expect(report).to include("Kept Skill Leftover: still used")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    let(:taxonomy) do
      { vendors: [ { name: "Microsoft" } ],
        categories: [ { name: "Office & Collaboration", was: [ "Office & Project" ], subcategories: [ { name: "Microsoft Office" } ] } ],
        skills: [ { name: "Excel", category: "Office & Collaboration › Microsoft Office", vendor: "Microsoft",
                    aliases: [ "MS Excel" ], remove_aliases: [ "Excell" ], description: "Spreadsheets." },
                  { name: "Teams", category: "Office & Collaboration", vendor: "Microsoft" } ],
        delete_skills: [ "Unused" ] }
    end

    before do
      office = create(:dossier_skill_category, name: "Office & Project")
      create(:dossier_skill, name: "Excel", aliases_text: "Excell", skill_category: office)
      create(:dossier_skill, name: "Unused", skill_category: office)
    end

    it "Changes nothing when run a second time" do
      apply(taxonomy)

      expect(apply(taxonomy)).to eq([])
      expect(skill("Excel").aliases).to eq([ "MS Excel" ])
    end

    it "Reports the changes but saves nothing on a dry run" do
      report = described_class.new(taxonomy.deep_stringify_keys).apply!(dry_run: true)

      expect(report).to include("Created Skill Teams", "Deleted Skill Unused")
      expect(skill("Teams")).to be_nil
      expect(skill("Unused")).to be_present
    end

    it "Keeps an existing description, filling in only blank ones" do
      skill("Excel").update!(description: "Your own words.")
      apply(taxonomy)

      expect(skill("Excel").description).to eq("Your own words.")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Deletes an emptied category only when listed, and keeps one that isn't empty" do
      crm = create(:dossier_skill_category, name: "CRM")
      erp = create(:dossier_skill_category, name: "ERP")
      create(:dossier_skill, name: "Salesforce", skill_category: crm)
      create(:dossier_skill, name: "Mapaz ERP", skill_category: erp)
      report = apply(categories: [ { name: "Business Applications", subcategories: [ { name: "Other" } ] } ],
                     skills: [ { name: "Salesforce", category: "Business Applications" } ],
                     delete_categories: [ "CRM", "ERP" ])

      expect(Dossier::SkillCategory.exists?(crm.id)).to be(false)
      expect(Dossier::SkillCategory.exists?(erp.id)).to be(true)
      expect(report).to include("Deleted Skill Category CRM", "Kept Skill Category ERP: it still has Skills")
    end

    it "Keeps and reports a listed category that still has sub-categories" do
      apply(categories: [ { name: "Testing", subcategories: [ { name: "Test Automation" } ] } ])

      expect(apply(delete_categories: [ "Testing" ])).to eq([ "Kept Skill Category Testing: it still has sub-categories" ])
    end

    it "Leaves Skills and categories it doesn't mention untouched" do
      sut = create(:dossier_skill_category, name: "System Under Test")
      qprime = create(:dossier_skill, name: "QPRIME", skill_category: sut)
      apply(categories: [ { name: "Testing" } ])

      expect(qprime.reload.skill_category).to eq(sut)
      expect(sut.reload.name).to eq("System Under Test")
    end

    it "Applies the committed taxonomy to an empty database, and a second run changes nothing" do
      taxonomy = YAML.safe_load_file(Rails.root.join("db/seeds/dossier/skill_taxonomy.yml"))

      expect(described_class.new(taxonomy).apply!).not_to be_empty
      expect(described_class.new(taxonomy).apply!).to eq([])
      expect(skill("MS Project").display_name).to eq("Microsoft Project")
      expect(skill("Windows XP").family_root.name).to eq("Windows")
    end

    it "Finds a category path and a Skill's old name ignoring case" do
      tools = create(:dossier_skill_category, name: "Tools")
      create(:dossier_skill, name: "putty", skill_category: tools)
      apply(categories: [ { name: "Tools" } ], skills: [ { name: "PuTTY", find: [ "PUTTY" ], category: "tools" } ])

      expect(Dossier::Skill.pluck(:name)).to eq([ "PuTTY" ])
    end
  end
end
