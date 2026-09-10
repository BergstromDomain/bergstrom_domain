# spec/views/shared/_toasts.html.erb_spec.rb
require "rails_helper"

RSpec.describe "shared/_toasts", type: :view do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "renders one styled toast per flash entry, mapping notice/alert to success/error" do
      flash[:notice] = "Person created"
      flash[:alert] = "Could not delete Person"

      render partial: "shared/toasts"

      expect(rendered).to have_css("[data-testid='toast-container']")
      expect(rendered).to have_css("[data-testid='flash-notice'].toast--success", text: "Person created")
      expect(rendered).to have_css("[data-testid='flash-alert'].toast--error", text: "Could not delete Person")
      expect(rendered).to have_css("[data-toast-dismiss-after-value='3000']", count: 2)
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "renders no container at all when there is no flash to show" do
      render partial: "shared/toasts"

      expect(rendered).to have_no_css("[data-testid='toast-container']")
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "renders the canonical info/warning variants directly, unmapped" do
      flash[:info] = "Alex Smith has been updated to Alexandra Anderson"
      flash[:warning] = "This post is still in Draft mode."

      render partial: "shared/toasts"

      expect(rendered).to have_css("[data-testid='flash-info'].toast--info")
      expect(rendered).to have_css("[data-testid='flash-warning'].toast--warning")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
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

    it "extends auto-dismiss to 5s for every toast in the render when an Info companion is present" do
      flash[:notice] = "Alexandra Anderson has been successfully updated"
      flash[:info] = "Alex Smith has been updated to Alexandra Anderson"

      render partial: "shared/toasts"

      expect(rendered).to have_css("[data-toast-dismiss-after-value='5000']", count: 2)
      expect(rendered).to have_no_css("[data-toast-dismiss-after-value='3000']")
    end
  end
end
