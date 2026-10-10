# spec/services/export_service_spec.rb
require "rails_helper"

RSpec.describe ExportService do
  let(:charlie) { create(:user, :content_creator) }

  def row(person:, event: nil)
    PersonEventFilter::Row.new(person: person, event: event)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Returns a string" do
      result = described_class.new([]).generate_csv
      expect(result).to be_a(String)
    end

    it "Includes the header row" do
      result = described_class.new([]).generate_csv
      expect(result.lines.first).to include("First name", "Last name", "Event type", "Event title", "Event date")
    end

    it "Includes one row per person+event combination" do
      event_type = create(:event_type, name: "Birthday")
      james = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
      lars  = create(:person, user: charlie, first_name: "Lars",  last_name: "Ulrich")
      james_event = create(:event, user: charlie, event_type: event_type, title: "James's Birthday")
      lars_event  = create(:event, user: charlie, event_type: event_type, title: "Lars's Birthday")

      rows = CSV.parse(described_class.new([
        row(person: james, event: james_event),
        row(person: lars, event: lars_event)
      ]).generate_csv, headers: true)

      expect(rows.length).to eq(2)
    end

    it "Generates one CSV row per given row, including repeated people" do
      birthday_type    = create(:event_type, name: "Birthday")
      anniversary_type = create(:event_type, name: "Anniversary")
      james = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
      birthday    = create(:event, user: charlie, event_type: birthday_type, title: "James's Birthday")
      anniversary = create(:event, user: charlie, event_type: anniversary_type, title: "James's Anniversary")

      rows = CSV.parse(described_class.new([
        row(person: james, event: birthday),
        row(person: james, event: anniversary)
      ]).generate_csv, headers: true)
      james_rows = rows.select { |r| r["First name"] == "James" }

      expect(james_rows.length).to eq(2)
    end

    it "Writes a row with blank event columns when the row has no event" do
      kirk = create(:person, user: charlie, first_name: "Kirk", last_name: "Hammett")

      rows = CSV.parse(described_class.new([ row(person: kirk) ]).generate_csv, headers: true)
      kirk_row = rows.first

      expect(kirk_row["First name"]).to eq("Kirk")
      expect(kirk_row["Event title"]).to be_nil
    end

    it "Formats the event date as YYYY-MM-DD" do
      person = create(:person, user: charlie)
      event  = create(:event, user: charlie, year: 2026, month: 3, day: 5)

      rows = CSV.parse(described_class.new([ row(person: person, event: event) ]).generate_csv, headers: true)
      expect(rows.first["Event date"]).to eq("2026-03-05")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Returns only a header row for an empty row list" do
      result = described_class.new([]).generate_csv
      lines  = result.strip.split("\n")
      expect(lines.length).to eq(1)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Leaves the Event date blank for an event with no year" do
      person = create(:person, user: charlie)
      event  = create(:event, :no_year, user: charlie)

      rows = CSV.parse(described_class.new([ row(person: person, event: event) ]).generate_csv, headers: true)
      expect(rows.first["Event date"]).to be_nil
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Preserves the given row order rather than re-sorting" do
      zed = create(:person, user: charlie, first_name: "Zed")
      amy = create(:person, user: charlie, first_name: "Amy")

      rows = CSV.parse(described_class.new([ row(person: zed), row(person: amy) ]).generate_csv, headers: true)
      expect(rows.map { |r| r["First name"] }).to eq([ "Zed", "Amy" ])
    end
  end
end
