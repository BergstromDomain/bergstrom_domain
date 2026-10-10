# spec/services/person_event_filter_spec.rb

require "rails_helper"

RSpec.describe PersonEventFilter do
  let(:owner) { create(:user, :content_creator) }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    describe ".attributes_for" do
      it "Builds the full attribute hash for a person+event row" do
        event_type = create(:event_type, name: "Birthday")
        person = create(:person, user: owner, first_name: "James", last_name: "Hetfield")
        event = create(:event, user: owner, event_type: event_type, title: "James's Birthday",
          year: 2026, month: 3, day: 15)

        row = described_class::Row.new(person: person, event: event)
        attrs = described_class.attributes_for(row)

        expect(attrs).to eq(
          first_name: "James",
          last_name:  "Hetfield",
          event_type: "Birthday",
          title:      "James's Birthday",
          date:       Date.new(2026, 3, 15)
        )
      end

      it "Uses nil for event fields when the row has no event" do
        person = create(:person, user: owner, first_name: "Kirk", last_name: "Hammett")
        row = described_class::Row.new(person: person, event: nil)

        attrs = described_class.attributes_for(row)

        expect(attrs[:event_type]).to be_nil
        expect(attrs[:title]).to be_nil
        expect(attrs[:date]).to be_nil
      end
    end

    describe ".basic_ast" do
      it "Returns nil (no filter) when every argument is blank" do
        expect(described_class.basic_ast).to be_nil
      end

      it "Builds an AST that matches only on the given First Name" do
        ast = described_class.basic_ast(first_name: "James")
        base = { first_name: "James", last_name: "Hetfield", event_type: "Birthday", title: "X", date: Date.current }

        expect(described_class::EVALUATOR.matches?(ast, base)).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(first_name: "Lars"))).to be false
      end

      it "Combines multiple filters with AND" do
        ast = described_class.basic_ast(first_name: "James", event_type: "Birthday")
        base = { first_name: "James", last_name: "Hetfield", event_type: "Birthday", title: "X", date: Date.current }

        expect(described_class::EVALUATOR.matches?(ast, base)).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(event_type: "Anniversary"))).to be false
      end

      it "Filters by the Date range boundaries" do
        range = Date.new(2026, 1, 1)..Date.new(2026, 1, 31)
        ast = described_class.basic_ast(date_range: range)
        base = { first_name: "X", last_name: "Y", event_type: "Z", title: "X" }

        expect(described_class::EVALUATOR.matches?(ast, base.merge(date: Date.new(2026, 1, 15)))).to be true
        expect(described_class::EVALUATOR.matches?(ast, base.merge(date: Date.new(2026, 2, 1)))).to be false
      end
    end

    describe ".sort" do
      it "Sorts rows by Last Name ascending and descending" do
        ulrich   = described_class::Row.new(person: create(:person, user: owner, first_name: "Lars", last_name: "Ulrich"), event: nil)
        hetfield = described_class::Row.new(person: create(:person, user: owner, first_name: "James", last_name: "Hetfield"), event: nil)

        expect(described_class.sort([ ulrich, hetfield ], :last_name, "asc")).to eq([ hetfield, ulrich ])
        expect(described_class.sort([ ulrich, hetfield ], :last_name, "desc")).to eq([ ulrich, hetfield ])
      end
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    describe ".basic_ast" do
      it "Returns false for every field when the filter doesn't match" do
        ast = described_class.basic_ast(first_name: "James", last_name: "Hetfield")
        base = { first_name: "Lars", last_name: "Ulrich", event_type: "Birthday", title: "X", date: Date.current }

        expect(described_class::EVALUATOR.matches?(ast, base)).to be false
      end
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    describe ".attributes_for" do
      it "Returns nil for date when the event's date is incomplete (no year)" do
        person = create(:person, user: owner)
        event = create(:event, user: owner, title: "Undated", year: nil, month: 6, day: 1)
        row = described_class::Row.new(person: person, event: event)

        expect(described_class.attributes_for(row)[:date]).to be_nil
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    describe ".sort" do
      it "Sorts rows with a nil sort value last, regardless of direction" do
        dated   = described_class::Row.new(person: create(:person, user: owner, last_name: "A"),
          event: create(:event, user: owner, title: "Dated", year: 2026, month: 1, day: 1))
        undated = described_class::Row.new(person: create(:person, user: owner, last_name: "B"), event: nil)

        expect(described_class.sort([ undated, dated ], :date, "asc").last).to eq(undated)
        expect(described_class.sort([ undated, dated ], :date, "desc").last).to eq(undated)
      end
    end
  end
end
