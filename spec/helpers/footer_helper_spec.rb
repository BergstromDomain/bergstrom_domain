# spec/helpers/footer_helper_spec.rb
require "rails_helper"

RSpec.describe FooterHelper, type: :helper do
  def stub_build_info(version: nil, git_sha: nil, build_date: nil)
    service = instance_double(BuildInfoService, version: version, git_sha: git_sha, build_date: build_date)
    allow(BuildInfoService).to receive(:new).and_return(service)
  end

  # Happy path
  describe "#footer_version" do
    it "Prefixes the version with a v" do
      stub_build_info(version: "1.2.3")

      expect(helper.footer_version).to eq("v1.2.3")
    end
  end

  describe "#footer_deploy_date" do
    it "Formats an ISO8601 build date as d-Mon-yyyy" do
      stub_build_info(build_date: "2026-01-01T12:00:00Z")

      expect(helper.footer_deploy_date).to eq("1-Jan-2026")
    end

    it "Formats a plain Y-m-d build date as d-Mon-yyyy" do
      stub_build_info(build_date: "2026-03-04")

      expect(helper.footer_deploy_date).to eq("4-Mar-2026")
    end
  end

  describe "#footer_git_sha" do
    it "Returns the short SHA as-is" do
      stub_build_info(git_sha: "c520c88")

      expect(helper.footer_git_sha).to eq("c520c88")
    end
  end

  # Negative path
  describe "with missing build info" do
    it "Falls back to 'unknown' for version, date, and git_sha rather than raising" do
      stub_build_info

      expect(helper.footer_version).to eq("unknown")
      expect(helper.footer_deploy_date).to eq("unknown")
      expect(helper.footer_git_sha).to eq("unknown")
    end
  end

  # Alternative path
  describe "#footer_environment_label" do
    it "Returns DEV in development" do
      allow(Rails).to receive(:env).and_return("development".inquiry)

      expect(helper.footer_environment_label).to eq("DEV")
    end

    it "Returns TEST in test" do
      allow(Rails).to receive(:env).and_return("test".inquiry)

      expect(helper.footer_environment_label).to eq("TEST")
    end
  end

  describe "#show_footer_environment_row?" do
    it "Returns true outside production" do
      allow(Rails).to receive(:env).and_return("development".inquiry)

      expect(helper.show_footer_environment_row?).to be(true)
    end

    it "Returns false in production" do
      allow(Rails).to receive(:env).and_return("production".inquiry)

      expect(helper.show_footer_environment_row?).to be(false)
    end
  end

  describe "#footer_class" do
    it "Adds the indented modifier when a left navbar is shown, so the footer aligns with the main frame" do
      assign(:show_left_nav, true)

      expect(helper.footer_class).to eq("site-footer site-footer--indented")
    end

    it "Uses the base class alone when there is no left navbar" do
      assign(:show_left_nav, false)

      expect(helper.footer_class).to eq("site-footer")
    end
  end

  # Edge cases
  describe "#footer_deploy_date with an unparseable value" do
    it "Falls back to 'unknown' rather than raising" do
      stub_build_info(build_date: "not-a-date")

      expect(helper.footer_deploy_date).to eq("unknown")
    end
  end

  describe "#footer_environment_label in an unrecognised Rails.env" do
    it "Returns nil rather than raising" do
      allow(Rails).to receive(:env).and_return("staging".inquiry)

      expect(helper.footer_environment_label).to be_nil
    end
  end
end
