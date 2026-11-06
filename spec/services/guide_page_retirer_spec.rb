# spec/services/guide_page_retirer_spec.rb

require "rails_helper"

RSpec.describe GuidePageRetirer do
  let(:root) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(root) }

  def retire(*titles)
    root.join("retired.yml").write(titles.to_yaml)
    described_class.new(root).call
  end

  def write_page(app, name, title)
    root.join(app).mkpath
    root.join(app, name).write({ "title" => title, "app_section" => "recipes" }.to_yaml + "---\n\nHelp.\n")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Deletes each listed page and reports it" do
      create(:guide_page, title: "Cookbook Overview")
      kept = create(:guide_page, title: "Finding Recipes")

      result = retire("Cookbook Overview")

      expect(GuidePage.all).to contain_exactly(kept)
      expect(result).to eq(removed: [ "Cookbook Overview" ], absent: [])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Refuses to retire a page that still has a Markdown file, and deletes nothing" do
      create(:guide_page, title: "Cookbook Overview")
      create(:guide_page, title: "Finding Recipes")
      write_page("cookbook", "02_finding_recipes.md", "Finding Recipes")

      expect { retire("Cookbook Overview", "finding recipes") }
        .to raise_error(GuidePageRetirer::Error, /finding recipes.*cookbook\/02_finding_recipes.md/i)
      expect(GuidePage.count).to eq(2)
    end

    it "Rejects a list that isn't a list of titles" do
      root.join("retired.yml").write({ "title" => "Cookbook Overview" }.to_yaml)

      expect { described_class.new(root).call }.to raise_error(GuidePageRetirer::Error, /list of titles/)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Reports a listed page that's already gone, so it's safe to run again" do
      result = retire("Cookbook Overview")

      expect(result).to eq(removed: [], absent: [ "Cookbook Overview" ])
    end

    it "Does nothing when there's no list" do
      expect(described_class.new(root).call).to eq(removed: [], absent: [])
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Matches titles ignoring case, like the loader" do
      create(:guide_page, title: "Cookbook Overview")

      expect(retire("cookbook overview")[:removed]).to eq([ "Cookbook Overview" ])
    end

    it "Retires every page in docs/user-guide/retired.yml" do
      %w[Chronicle Cookbook Occasions].each { |app| create(:guide_page, title: "#{app} Overview") }

      result = described_class.new(Rails.root.join("docs/user-guide")).call

      expect(result[:removed]).to contain_exactly("Chronicle Overview", "Cookbook Overview", "Occasions Overview")
    end
  end
end
