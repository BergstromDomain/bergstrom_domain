# spec/views/shared/_confirm_dialog.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_confirm_dialog", type: :view do
  # Happy path
  it "renders a native dialog wired to the Stimulus controller, with a message target and both buttons" do
    render partial: "shared/confirm_dialog"

    expect(rendered).to have_css("dialog.confirm-dialog[data-controller='confirm-dialog']")
    expect(rendered).to have_css("dialog[data-testid='confirm-dialog']")
    expect(rendered).to have_css("dialog[data-confirm-dialog-target='dialog']")
    expect(rendered).to have_css("p[data-confirm-dialog-target='message']", visible: :all)
  end

  it "labels the dialog via aria-labelledby pointing at the message paragraph" do
    render partial: "shared/confirm_dialog"

    expect(rendered).to have_css("dialog[aria-labelledby='confirm-dialog-message']")
    expect(rendered).to have_css("p#confirm-dialog-message", visible: :all)
  end

  it "renders a danger-styled Confirm button and a secondary Cancel button" do
    render partial: "shared/confirm_dialog"

    expect(rendered).to have_css(
      "button.btn-danger[data-confirm-dialog-target='confirmButton'][data-action='confirm-dialog#confirm'][data-testid='confirm-dialog-confirm']",
      text: "Confirm", visible: :all
    )
    expect(rendered).to have_css(
      "button.btn-secondary[data-confirm-dialog-target='cancelButton'][data-action='confirm-dialog#cancel'][data-testid='confirm-dialog-cancel']",
      text: "Cancel", visible: :all
    )
  end

  # Negative path
  it "renders exactly one dialog and does not render with any content pre-filled" do
    render partial: "shared/confirm_dialog"

    expect(rendered.scan("<dialog").size).to eq(1)
    expect(rendered).to have_css("p[data-confirm-dialog-target='message']", text: "", visible: :all)
  end

  # Alternative path
  it "does not render the dialog as open by default" do
    render partial: "shared/confirm_dialog"

    expect(rendered).not_to have_css("dialog[open]", visible: :all)
  end

  # Edge cases
  it "does not interpolate any caller-provided message into the static markup (message is set via JS)" do
    render partial: "shared/confirm_dialog"

    expect(rendered).to have_css("p[data-confirm-dialog-target='message']", visible: :all)
    expect(rendered.scan('data-confirm-dialog-target="message"').size).to eq(1)
  end
end
