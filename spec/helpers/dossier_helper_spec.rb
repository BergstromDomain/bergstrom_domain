# spec/helpers/dossier_helper_spec.rb
require "rails_helper"

RSpec.describe DossierHelper, type: :helper do
  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Links an http(s) URL in a new tab" do
      expect(helper.external_link("https://example.com/verify/1"))
        .to eq('<a target="_blank" rel="noopener" href="https://example.com/verify/1">https://example.com/verify/1</a>')
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Shows any other scheme as plain, escaped text" do
      expect(helper.external_link("javascript:alert(1)")).to eq("javascript:alert(1)")
      expect(helper.external_link("<b>x</b>")).to eq("&lt;b&gt;x&lt;/b&gt;")
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Shows a dash for no URL" do
      expect(helper.external_link(nil)).to eq("—")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Accepts an upper-case scheme" do
      expect(helper.external_link("HTTPS://example.com")).to include('href="HTTPS://example.com"')
    end
  end
end
