# spec/services/guide_page_loader_spec.rb

require "rails_helper"

RSpec.describe GuidePageLoader do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  after { FileUtils.remove_entry(directory) }

  def write_page(name, title:, app_section: "recipes", body: "Some help.", **flags)
    front_matter = { "title" => title, "app_section" => app_section }.merge(flags.transform_keys(&:to_s))
    directory.join(name).write("#{front_matter.to_yaml}---\n\n#{body}\n")
  end

  def load_pages
    described_class.new(directory).call
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Creates a guide page from each Markdown file's front matter and body" do
      write_page("01_overview.md", title: "Cookbook Overview", body: "## Welcome\n\nHello.",
        supports_guest: true, supports_user: true, supports_content_creator: false)

      result = load_pages

      page = GuidePage.find_by!(title: "Cookbook Overview")
      expect(page).to have_attributes(app_section: "recipes", supports_guest: true, supports_user: true,
        supports_content_creator: false)
      expect(page.body).to eq("## Welcome\n\nHello.")
      expect(result).to eq(created: [ "Cookbook Overview" ], updated: [], unchanged: [])
    end

    it "Updates an existing page with the same title, ignoring case, instead of duplicating it" do
      existing = create(:guide_page, title: "cookbook overview", app_section: "recipes", body: "Old text.")
      write_page("01_overview.md", title: "Cookbook Overview", body: "New text.")

      result = load_pages

      expect(GuidePage.count).to eq(1)
      expect(existing.reload).to have_attributes(title: "Cookbook Overview", body: "New text.")
      expect(result[:updated]).to eq([ "Cookbook Overview" ])
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Rejects a file without front matter, naming the file and saving nothing" do
      write_page("01_good.md", title: "Good Page")
      directory.join("02_bad.md").write("Just a body.\n")

      expect { load_pages }.to raise_error(GuidePageLoader::Error, /02_bad\.md/)
      expect(GuidePage.count).to eq(0)
    end

    it "Rejects an invalid page, naming the file and the problem" do
      write_page("01_bad.md", title: "Bad Section", app_section: "no_such_app")

      expect { load_pages }.to raise_error(GuidePageLoader::Error, /01_bad\.md.*App section/)
    end

    it "Rejects a directory that doesn't exist" do
      expect { described_class.new(directory.join("missing")).call }.to raise_error(GuidePageLoader::Error, /missing/)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Leaves an identical page untouched" do
      write_page("01_overview.md", title: "Cookbook Overview")
      load_pages

      expect { expect(load_pages).to eq(created: [], updated: [], unchanged: [ "Cookbook Overview" ]) }
        .not_to(change { GuidePage.first.updated_at })
    end

    it "Defaults a missing support flag to false" do
      write_page("01_admin.md", title: "Managing Reference Data", app_section: "admin")
      load_pages

      expect(GuidePage.first).to have_attributes(supports_guest: false, supports_user: false, supports_content_creator: false)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Ignores files that aren't Markdown" do
      write_page("01_overview.md", title: "Cookbook Overview")
      directory.join("notes.txt").write("Not a page")

      expect(load_pages[:created]).to eq([ "Cookbook Overview" ])
    end

    it "Keeps '---' inside the body" do
      write_page("01_overview.md", title: "Cookbook Overview", body: "Above\n\n---\n\nBelow")
      load_pages

      expect(GuidePage.first.body).to eq("Above\n\n---\n\nBelow")
    end

    it "Loads every page in docs/user-guide/chronicle" do
      result = described_class.new(Rails.root.join("docs/user-guide/chronicle")).call

      expect(result[:created]).to contain_exactly(
        "Chronicle Overview", "Reading Blog Posts", "Writing A Blog Post",
        "Importing And Downloading Blog Posts", "Chronicle Settings", "Managing Chronicle Reference Data"
      )
      expect(GuidePage.find_by!(title: "Managing Chronicle Reference Data").app_section).to eq("admin")
    end

    it "Loads every page in docs/user-guide/cookbook" do
      result = described_class.new(Rails.root.join("docs/user-guide/cookbook")).call

      expect(result[:created]).to contain_exactly(
        "Cookbook Overview", "Finding Recipes", "Writing A Recipe", "Downloading Recipes",
        "Cookbook Settings", "Managing Cookbook Reference Data"
      )
      expect(GuidePage.find_by!(title: "Managing Cookbook Reference Data").app_section).to eq("admin")
    end
  end
end
