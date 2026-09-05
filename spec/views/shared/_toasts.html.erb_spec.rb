# spec/views/shared/_toasts.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_toasts", type: :view do
  # Happy path
  it "renders one styled toast per flash entry, mapping notice/alert to success/error" do
    flash[:notice] = "Person created"
    flash[:alert] = "Could not delete Person"

    render partial: "shared/toasts"

    expect(rendered).to have_css("[data-testid='toast-container']")
    expect(rendered).to have_css("[data-testid='flash-notice'].toast--success", text: "Person created")
    expect(rendered).to have_css("[data-testid='flash-alert'].toast--error", text: "Could not delete Person")
  end

  # Negative path
  it "renders no container at all when there is no flash to show" do
    render partial: "shared/toasts"

    expect(rendered).to have_no_css("[data-testid='toast-container']")
  end

  # Alternative path
  it "renders the canonical info/warning variants directly, unmapped" do
    flash[:info] = "Alex Smith has been updated to Alexandra Anderson"
    flash[:warning] = "This post is still in Draft mode."

    render partial: "shared/toasts"

    expect(rendered).to have_css("[data-testid='flash-info'].toast--info")
    expect(rendered).to have_css("[data-testid='flash-warning'].toast--warning")
  end

  # Edge cases
  it "stacks Success above Info regardless of flash assignment order" do
    # :info assigned first, deliberately reversed from the desired render order, to prove the
    # stacking order doesn't depend on flash hash insertion order.
    flash[:info] = "Alex Smith has been updated to Alexandra Anderson"
    flash[:notice] = "Alexandra Anderson has been successfully updated"

    render partial: "shared/toasts"

    success_index = rendered.index("Alexandra Anderson has been successfully updated")
    info_index = rendered.index("Alex Smith has been updated to Alexandra Anderson")
    expect(success_index).to be < info_index
  end
end
