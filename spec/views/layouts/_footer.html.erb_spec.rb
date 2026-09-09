# spec/views/layouts/_footer.html.erb_spec.rb
require "rails_helper"

RSpec.describe "layouts/_footer", type: :view do
  before do
    allow(view).to receive(:footer_version).and_return("v1.0.0")
    allow(view).to receive(:footer_deploy_date).and_return("6-Sep-2026")
    allow(view).to receive(:footer_git_sha).and_return("abc1234")
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders the version and deploy date row" do
      allow(view).to receive(:show_footer_environment_row?).and_return(false)

      render partial: "layouts/footer"

      expect(rendered).to have_css("[data-testid='footer-version']", text: "Version: v1.0.0")
      expect(rendered).to have_css("[data-testid='footer-date']", text: "Deployed Date: 6-Sep-2026")
    end

    it "bolds each label" do
      allow(view).to receive(:show_footer_environment_row?).and_return(false)

      render partial: "layouts/footer"

      expect(rendered).to have_css("[data-testid='footer-version'] strong.site-footer__label", text: "Version:")
      expect(rendered).to have_css("[data-testid='footer-date'] strong.site-footer__label", text: "Deployed Date:")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "renders the environment and git row in a non-production environment" do
      allow(view).to receive(:show_footer_environment_row?).and_return(true)
      allow(view).to receive(:footer_environment_label).and_return("DEV")

      render partial: "layouts/footer"

      expect(rendered).to have_css("[data-testid='footer-environment']", text: "Environment: DEV")
      expect(rendered).to have_css("[data-testid='footer-git-sha']", text: "Git: abc1234")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "omits the environment/git row entirely in production" do
      allow(view).to receive(:show_footer_environment_row?).and_return(false)

      render partial: "layouts/footer"

      expect(rendered).to have_no_css("[data-testid='footer-row-environment']")
    end

    it "adds the indented modifier class when a left navbar is shown" do
      allow(view).to receive(:show_footer_environment_row?).and_return(false)
      assign(:show_left_nav, true)

      render partial: "layouts/footer"

      expect(rendered).to have_css("footer.site-footer.site-footer--indented")
    end

    it "omits the indented modifier class when there is no left navbar" do
      allow(view).to receive(:show_footer_environment_row?).and_return(false)
      assign(:show_left_nav, false)

      render partial: "layouts/footer"

      expect(rendered).to have_css("footer.site-footer")
      expect(rendered).to have_no_css("footer.site-footer--indented")
    end
  end
end
