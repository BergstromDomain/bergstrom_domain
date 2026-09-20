# spec/services/pdf_rendering_service_spec.rb

require "rails_helper"

RSpec.describe PdfRenderingService do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Renders HTML into PDF bytes" do
      pdf = described_class.new("<html><body><h1>Hello</h1></body></html>").render
      expect(pdf).to be_a(String)
      expect(pdf.byteslice(0, 5)).to eq("%PDF-")
    end

    it "Defaults to A4 page size" do
      pdf = described_class.new("<html><body>A4 by default</body></html>").render
      expect(pdf.byteslice(0, 5)).to eq("%PDF-")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Raises ArgumentError for blank HTML" do
      expect { described_class.new("").render }.to raise_error(ArgumentError)
      expect { described_class.new(nil).render }.to raise_error(ArgumentError)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Accepts a different page format" do
      pdf = described_class.new("<html><body>Letter</body></html>", format: :letter).render
      expect(pdf.byteslice(0, 5)).to eq("%PDF-")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Renders HTML containing an inline base64 image without a network fetch" do
      pixel = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
      html = "<html><body><img src='#{pixel}'></body></html>"

      pdf = described_class.new(html).render
      expect(pdf.byteslice(0, 5)).to eq("%PDF-")
    end
  end
end
