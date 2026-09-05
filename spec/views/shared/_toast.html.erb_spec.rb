# spec/views/shared/_toast.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_toast", type: :view do
  # Happy path
  it "renders the message, the variant's icon and styling class, and a dismiss control" do
    render partial: "shared/toast", locals: { variant: "success", message: "Person created" }

    expect(rendered).to have_css(".toast.toast--success[role='status'][aria-live='polite']")
    expect(rendered).to have_css(".toast__message", text: "Person created")
    expect(rendered).to have_css(".toast__icon svg")
    expect(rendered).to have_css("[data-testid='flash-success']")
    expect(rendered).to have_css("button.toast__close[data-action='toast#dismiss']")
  end

  it "wires the auto-dismiss timer via Stimulus data attributes by default" do
    render partial: "shared/toast", locals: { variant: "success", message: "Person created" }

    expect(rendered).to have_css("[data-controller='toast'][data-toast-dismiss-after-value='3000']")
  end

  # Negative path
  it "falls back to the info icon without raising for an unrecognised variant" do
    expect {
      render partial: "shared/toast", locals: { variant: "some_future_variant", message: "Hi" }
    }.not_to raise_error

    expect(rendered).to have_css(".toast--some_future_variant")
  end

  # Alternative path
  it "omits the dismiss control and the auto-dismiss timer when dismissible: false" do
    render partial: "shared/toast",
           locals: { variant: "warning", message: "Still a draft", dismissible: false }

    expect(rendered).to have_no_css("button.toast__close")
    expect(rendered).to have_no_css("[data-controller='toast']")
  end

  # Edge cases
  it "defaults the data-testid to the variant name when flash_key isn't given" do
    render partial: "shared/toast", locals: { variant: "warning", message: "Still a draft" }

    expect(rendered).to have_css("[data-testid='flash-warning']")
  end

  it "uses flash_key for the data-testid when it differs from the visual variant" do
    render partial: "shared/toast",
           locals: { variant: "success", message: "Done", flash_key: "notice" }

    expect(rendered).to have_css(".toast--success[data-testid='flash-notice']")
  end

  it "uses an explicit testid override for non-flash usage (e.g. a state-based toast)" do
    render partial: "shared/toast",
           locals: { variant: "warning", message: "Still a draft", testid: "draft-mode-warning", dismissible: false }

    expect(rendered).to have_css(".toast--warning[data-testid='draft-mode-warning']")
  end

  it "uses an explicit dismiss_after override instead of the 3s default" do
    render partial: "shared/toast",
           locals: { variant: "success", message: "Done", dismiss_after: 5000 }

    expect(rendered).to have_css("[data-toast-dismiss-after-value='5000']")
  end

  it "HTML-escapes the message" do
    render partial: "shared/toast",
           locals: { variant: "success", message: "<script>alert(1)</script>" }

    expect(rendered).not_to include("<script>")
    expect(rendered).to have_css(".toast__message", text: "<script>alert(1)</script>")
  end
end
