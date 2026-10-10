# spec/services/zip_bundling_service_spec.rb

require "rails_helper"

RSpec.describe ZipBundlingService do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Returns zip bytes containing every entry under its given filename" do
      zip_data = described_class.new("a.txt" => "hello", "b.txt" => "world").generate

      names = []
      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        while (entry = io.get_next_entry)
          names << entry.name
        end
      end

      expect(names).to contain_exactly("a.txt", "b.txt")
    end

    it "Preserves each entry's exact content" do
      zip_data = described_class.new("a.txt" => "hello").generate

      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        io.get_next_entry
        expect(io.read).to eq("hello")
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns a valid, empty zip for no entries" do
      zip_data = described_class.new({}).generate

      names = []
      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        while (entry = io.get_next_entry)
          names << entry.name
        end
      end

      expect(names).to eq([])
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Handles binary (non-UTF-8-safe) content correctly" do
      binary = Random.bytes(64)
      zip_data = described_class.new("data.bin" => binary).generate

      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        io.get_next_entry
        expect(io.read).to eq(binary)
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Handles a single entry with empty content" do
      zip_data = described_class.new("empty.txt" => "").generate

      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        entry = io.get_next_entry
        expect(entry.name).to eq("empty.txt")
        expect(io.read).to eq("")
      end
    end
  end
end
