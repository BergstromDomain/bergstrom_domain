# spec/views/shared/_popup.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_popup", type: :view do
  def render_popup(testid: "test-popup", &block)
    render layout: "shared/popup", locals: { testid: testid }, &block
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders a native dialog wired to the Stimulus controller's dialog target" do
      render_popup { "Popup body content" }

      expect(rendered).to have_css("dialog.popup[data-popup-target='dialog']")
      expect(rendered).to have_css("dialog[data-testid='test-popup']")
    end

    it "renders the yielded content inside .popup__content" do
      render_popup { "Popup body content" }

      expect(rendered).to have_css(".popup__content", text: "Popup body content")
    end

    it "renders a close button wired to popup#close" do
      render_popup { "content" }

      expect(rendered).to have_css(
        "button.popup__close[data-action='popup#close'][data-testid='test-popup-close'][aria-label='Close']"
      )
      expect(rendered).to have_css("button[data-testid='test-popup-close'] svg")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "renders exactly one dialog, with no content when the block is empty" do
      render_popup { "" }

      expect(rendered.scan("<dialog").size).to eq(1)
      expect(rendered).to have_css(".popup__content", text: "")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "namespaces the testid on both the dialog and its close button, per caller" do
      render_popup(testid: "likes-breakdown-popup") { "content" }

      expect(rendered).to have_css("dialog[data-testid='likes-breakdown-popup']")
      expect(rendered).to have_css("button[data-testid='likes-breakdown-popup-close']")
    end

    it "does not render the dialog as open by default" do
      render_popup { "content" }

      expect(rendered).not_to have_css("dialog[open]")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "renders arbitrary caller-provided markup inside the content area unescaped" do
      render_popup { "<p class='custom'>Nested markup</p>".html_safe }

      expect(rendered).to have_css(".popup__content p.custom", text: "Nested markup")
    end
  end
end
