# spec/services/export_service_spec.rb
require "rails_helper"

RSpec.describe ExportService do
  let(:charlie) { create(:user, :content_creator) }

  describe "#generate_csv" do
    context "Happy path" do
      it "Returns a string" do
        result = described_class.new(charlie, [ :contacts ]).generate_csv
        expect(result).to be_a(String)
      end

      it "Includes the header row" do
        result = described_class.new(charlie, [ :contacts ]).generate_csv
        expect(result.lines.first).to include("First name", "Last name", "Event type", "Event title", "Event date")
      end

      it "Includes one row per person+event combination" do
        event_type = create(:event_type, name: "Birthday")
        james      = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
        lars       = create(:person, user: charlie, first_name: "Lars",  last_name: "Ulrich")
        create(:event, user: charlie, event_type: event_type, title: "James's Birthday").tap { |e| e.people << james }
        create(:event, user: charlie, event_type: event_type, title: "Lars's Birthday").tap  { |e| e.people << lars }

        rows = CSV.parse(described_class.new(charlie, [ :contacts ]).generate_csv, headers: true)
        expect(rows.length).to eq(2)
      end

      it "Generates multiple rows for a person with multiple events" do
        birthday_type    = create(:event_type, name: "Birthday")
        anniversary_type = create(:event_type, name: "Anniversary")
        james            = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")
        create(:event, user: charlie, event_type: birthday_type,    title: "James's Birthday").tap    { |e| e.people << james }
        create(:event, user: charlie, event_type: anniversary_type, title: "James's Anniversary").tap { |e| e.people << james }

        rows = CSV.parse(described_class.new(charlie, [ :contacts ]).generate_csv, headers: true)
        james_rows = rows.select { |r| r["First name"] == "James" }
        expect(james_rows.length).to eq(2)
      end

      it "Includes a person with no events as a row with blank event columns" do
        create(:person, user: charlie, first_name: "Kirk", last_name: "Hammett")

        rows = CSV.parse(described_class.new(charlie, [ :contacts ]).generate_csv, headers: true)
        kirk = rows.find { |r| r["First name"] == "Kirk" }

        expect(kirk).not_to be_nil
        expect(kirk["Event title"]).to be_nil
      end

      it "Orders rows by last name then first name" do
        create(:person, user: charlie, first_name: "Lars",  last_name: "Ulrich")
        create(:person, user: charlie, first_name: "James", last_name: "Hetfield")

        rows      = CSV.parse(described_class.new(charlie, [ :contacts ]).generate_csv, headers: true)
        last_names = rows.map { |r| r["Last name"] }

        expect(last_names).to eq(last_names.sort_by(&:downcase))
      end
    end

    context "Negative path" do
      it "Returns only a header row when no matching data exists" do
        result = described_class.new(charlie, [ :contacts ]).generate_csv
        lines  = result.strip.split("\n")
        expect(lines.length).to eq(1)
      end

      it "Does not include another user's private data" do
        adam        = create(:user, :admin)
        their_person = create(:person, user: adam, first_name: "Dave", last_name: "Mustaine")
        my_person    = create(:person, user: charlie, first_name: "James", last_name: "Hetfield")

        rows = CSV.parse(described_class.new(charlie, [ :contacts ]).generate_csv, headers: true)
        names = rows.map { |r| r["First name"] }

        expect(names).to include("James")
        expect(names).not_to include("Dave")
      end
    end
  end
end
