# spec/views/shared/_confirm_dialog.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_confirm_dialog", type: :view do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders a native dialog wired to the Stimulus controller, with a message target and both buttons" do
      render partial: "shared/confirm_dialog"

      expect(rendered).to have_css("dialog.confirm-dialog[data-controller='confirm-dialog']")
      expect(rendered).to have_css("dialog[data-testid='confirm-dialog']")
      expect(rendered).to have_css("dialog[data-confirm-dialog-target='dialog']")
      expect(rendered).to have_css("p[data-confirm-dialog-target='message']", visible: :all)
    end

    it "labels the dialog via aria-labelledby/aria-describedby pointing at the question and detail paragraphs" do
      render partial: "shared/confirm_dialog"

      expect(rendered).to have_css("dialog[aria-labelledby='confirm-dialog-message']")
      expect(rendered).to have_css("dialog[aria-describedby='confirm-dialog-detail']")
      expect(rendered).to have_css("p#confirm-dialog-message", visible: :all)
      expect(rendered).to have_css("p#confirm-dialog-detail", visible: :all)
    end

    it "wraps the question and detail paragraphs in a bordered, tinted message box" do
      render partial: "shared/confirm_dialog"

      expect(rendered).to have_css(
        ".confirm-dialog__message-box p.confirm-dialog__question[data-confirm-dialog-target='message']",
        visible: :all
      )
      expect(rendered).to have_css(
        ".confirm-dialog__message-box p.confirm-dialog__detail[data-confirm-dialog-target='detail']",
        visible: :all
      )
    end

    it "renders a danger-styled Confirm button and a secondary Cancel button, both using the base .btn class and an icon" do
      render partial: "shared/confirm_dialog"

      expect(rendered).to have_css(
        "button.btn.btn-danger[data-confirm-dialog-target='confirmButton'][data-action='confirm-dialog#confirm'][data-testid='confirm-dialog-confirm']",
        text: "Confirm", visible: :all
      )
      expect(rendered).to have_css("button[data-testid='confirm-dialog-confirm'] svg", visible: :all)
      expect(rendered).to have_css(
        "button.btn.btn-secondary[data-confirm-dialog-target='cancelButton'][data-action='confirm-dialog#cancel'][data-testid='confirm-dialog-cancel']",
        text: "Cancel", visible: :all
      )
      expect(rendered).to have_css("button[data-testid='confirm-dialog-cancel'] svg", visible: :all)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "renders exactly one dialog and does not render with any content pre-filled" do
      render partial: "shared/confirm_dialog"

      expect(rendered.scan("<dialog").size).to eq(1)
      expect(rendered).to have_css("p[data-confirm-dialog-target='message']", text: "", visible: :all)
      expect(rendered).to have_css("p[data-confirm-dialog-target='detail']", text: "", visible: :all)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "does not render the dialog as open by default, and hides the detail row by default" do
      render partial: "shared/confirm_dialog"

      expect(rendered).not_to have_css("dialog[open]", visible: :all)
      expect(rendered).to have_css("p[data-confirm-dialog-target='detail'][hidden]", visible: :all)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "does not interpolate any caller-provided message into the static markup (message is set via JS)" do
      render partial: "shared/confirm_dialog"

      expect(rendered).to have_css("p[data-confirm-dialog-target='message']", visible: :all)
      expect(rendered.scan('data-confirm-dialog-target="message"').size).to eq(1)
      expect(rendered.scan('data-confirm-dialog-target="detail"').size).to eq(1)
    end
  end
end
