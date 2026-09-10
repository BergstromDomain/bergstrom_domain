# spec/helpers/toast_helper_spec.rb
require "rails_helper"

RSpec.describe ToastHelper, type: :helper do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    describe "#toast_variant_for" do
      it "maps the canonical variant keys onto themselves" do
        expect(helper.toast_variant_for("success")).to eq("success")
        expect(helper.toast_variant_for("info")).to eq("info")
        expect(helper.toast_variant_for("warning")).to eq("warning")
        expect(helper.toast_variant_for("error")).to eq("error")
      end

      it "maps Rails' built-in flash keys onto a visual variant for backward compatibility" do
        expect(helper.toast_variant_for("notice")).to eq("success")
        expect(helper.toast_variant_for("alert")).to eq("error")
      end

      it "accepts symbol flash keys, not just strings" do
        expect(helper.toast_variant_for(:notice)).to eq("success")
      end
    end

    describe "#toast_icon_for" do
      it "returns the expected Lucide icon name for each canonical variant" do
        expect(helper.toast_icon_for("success")).to eq("circle-check")
        expect(helper.toast_icon_for("info")).to eq("info")
        expect(helper.toast_icon_for("warning")).to eq("triangle-alert")
        expect(helper.toast_icon_for("error")).to eq("circle-alert")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    describe "with nil input" do
      it "does not raise, and falls back to the info variant/icon" do
        expect(helper.toast_variant_for(nil)).to eq("info")
        expect(helper.toast_icon_for(nil)).to eq("info")
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    describe "with an unrecognised flash key" do
      it "falls back to the info variant rather than raising" do
        expect(helper.toast_variant_for("some_future_flash_key")).to eq("info")
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    describe "with an unrecognised variant name" do
      it "falls back to the info icon rather than raising" do
        expect(helper.toast_icon_for("some_future_variant")).to eq("info")
      end
    end
  end
end
