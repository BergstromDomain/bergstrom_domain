# spec/support/shared_examples/dossier_named_reference_data.rb

# Shared model examples for Dossier reference data identified by a unique name
# (Industry, Role, Skill Category, Employment Type, Organisation, Skill).
RSpec.shared_examples "Dossier named reference data" do |factory|
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path (named reference data)" do
    it "Is valid without a description" do
      expect(build(factory, description: nil)).to be_valid
    end

    it "Uses its name as the toast label and the slug" do
      record = create(factory, name: "Quality Assurance")
      expect(record.to_toast_label).to eq("Quality Assurance")
      expect(record.slug).to eq("quality-assurance")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path (named reference data)" do
    it "Is invalid without a name" do
      record = build(factory, name: "")
      expect(record).not_to be_valid
      expect(record.errors[:name]).to include("can't be blank")
    end

    it "Is invalid with a duplicate name in a different case" do
      create(factory, name: "Quality Assurance")
      record = build(factory, name: "quality assurance")
      expect(record).not_to be_valid
      expect(record.errors[:name]).to include("has already been taken")
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path (named reference data)" do
    it "Is still found by its old slug after a rename" do
      record = create(factory, name: "Quality Assurance")
      record.update!(name: "Quality Engineering")
      expect(described_class.friendly.find("quality-assurance")).to eq(record)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases (named reference data)" do
    it "Strips surrounding whitespace from the name" do
      expect(create(factory, name: "  Quality Assurance  ").name).to eq("Quality Assurance")
    end

    it "Sorts case-insensitively by name" do
      b = create(factory, name: "beta")
      a = create(factory, name: "Alpha")
      expect(described_class.alphabetical.where(id: [ a.id, b.id ])).to eq([ a, b ])
    end
  end
end
