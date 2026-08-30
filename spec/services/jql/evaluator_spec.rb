# spec/services/jql/evaluator_spec.rb

require "rails_helper"

RSpec.describe Jql::Evaluator do
  let(:schema) { { title: :string, comments: :integer, smiles: :decimal, created: :date } }
  let(:evaluator) { described_class.new(schema) }

  def comparison(field:, operator:, value:, value_type:)
    Jql::Parser::Comparison.new(field: field, operator: operator, value: value, value_type: value_type)
  end

  def string_comparison(field, operator, value)
    comparison(field: field, operator: operator, value: value, value_type: :string)
  end

  def number_comparison(field, operator, value)
    comparison(field: field, operator: operator, value: value, value_type: :number)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    describe "#validate!" do
      it "Accepts a valid comparison for each declared field" do
        expect { evaluator.validate!(string_comparison(:title, "=", "Hello")) }.not_to raise_error
        expect { evaluator.validate!(number_comparison(:comments, ">", 1)) }.not_to raise_error
        expect { evaluator.validate!(number_comparison(:smiles, ">=", 3.5)) }.not_to raise_error
        expect { evaluator.validate!(string_comparison(:created, "=", "2026-01-01")) }.not_to raise_error
      end

      it "Accepts an AND/OR tree where every leaf is valid" do
        ast = Jql::Parser::And.new(
          left: string_comparison(:title, "CONTAINS", "rails"),
          right: Jql::Parser::Or.new(
            left: number_comparison(:comments, ">", 1),
            right: number_comparison(:smiles, ">=", 3.0)
          )
        )
        expect { evaluator.validate!(ast) }.not_to raise_error
      end
    end

    describe "#matches?" do
      it "Matches string equality case-insensitively" do
        ast = string_comparison(:title, "=", "hello world")
        expect(evaluator.matches?(ast, title: "Hello World")).to be true
        expect(evaluator.matches?(ast, title: "Something Else")).to be false
      end

      it "Matches CONTAINS as a case-insensitive substring" do
        ast = string_comparison(:title, "CONTAINS", "RAILS")
        expect(evaluator.matches?(ast, title: "Learning Ruby on Rails")).to be true
      end

      it "Matches numeric ordering operators" do
        ast = number_comparison(:comments, ">", 3)
        expect(evaluator.matches?(ast, comments: 5)).to be true
        expect(evaluator.matches?(ast, comments: 2)).to be false
      end

      it "Matches date comparisons against the record's date" do
        ast = string_comparison(:created, ">=", "2026-01-01")
        expect(evaluator.matches?(ast, created: Time.zone.parse("2026-06-01"))).to be true
        expect(evaluator.matches?(ast, created: Time.zone.parse("2025-01-01"))).to be false
      end

      it "Combines AND correctly (both sides must match)" do
        ast = Jql::Parser::And.new(
          left: string_comparison(:title, "CONTAINS", "rails"),
          right: number_comparison(:comments, ">", 1)
        )
        expect(evaluator.matches?(ast, title: "Ruby on Rails", comments: 2)).to be true
        expect(evaluator.matches?(ast, title: "Ruby on Rails", comments: 0)).to be false
      end

      it "Combines OR correctly (either side may match)" do
        ast = Jql::Parser::Or.new(
          left: string_comparison(:title, "=", "Ruby"),
          right: number_comparison(:comments, ">", 10)
        )
        expect(evaluator.matches?(ast, title: "Something Else", comments: 20)).to be true
      end
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Raises on an unknown field" do
      expect { evaluator.validate!(string_comparison(:bogus, "=", "x")) }
        .to raise_error(Jql::ParseError, /Unknown field 'bogus'/)
    end

    it "Raises when an ordering operator is used on a text field" do
      expect { evaluator.validate!(string_comparison(:title, ">", "Hello")) }
        .to raise_error(Jql::ParseError, /not valid for text field/)
    end

    it "Raises when CONTAINS is used on a numeric field" do
      expect { evaluator.validate!(comparison(field: :comments, operator: "CONTAINS", value: "5", value_type: :string)) }
        .to raise_error(Jql::ParseError, /CONTAINS.*text field/)
    end

    it "Raises when a string literal is given for a numeric field" do
      expect { evaluator.validate!(comparison(field: :comments, operator: ">", value: "five", value_type: :string)) }
        .to raise_error(Jql::ParseError, /expects a number/)
    end

    it "Raises when a numeric literal is given for a text field" do
      expect { evaluator.validate!(comparison(field: :title, operator: "=", value: 5, value_type: :number)) }
        .to raise_error(Jql::ParseError, /expects text/)
    end

    it "Raises when a date field's value doesn't parse as a date" do
      expect { evaluator.validate!(string_comparison(:created, "=", "not-a-date")) }
        .to raise_error(Jql::ParseError, /Invalid date/)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Matches != as the negation of =" do
      ast = string_comparison(:title, "!=", "Hello")
      expect(evaluator.matches?(ast, title: "Goodbye")).to be true
      expect(evaluator.matches?(ast, title: "Hello")).to be false
    end

    it "Matches a decimal (Smiles-style) field" do
      schema_with_smiles = described_class.new(title: :string, smiles: :decimal)
      ast = number_comparison(:smiles, ">=", 3.5)
      expect(schema_with_smiles.matches?(ast, smiles: 4.0)).to be true
      expect(schema_with_smiles.matches?(ast, smiles: 3.0)).to be false
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Never matches a string comparison when the record's value is nil" do
      ast = string_comparison(:title, "=", "Ruby")
      expect(evaluator.matches?(ast, title: nil)).to be false
    end

    it "Treats a nil record value as not matching CONTAINS either" do
      ast = string_comparison(:title, "CONTAINS", "Ruby")
      expect(evaluator.matches?(ast, title: nil)).to be false
    end

    it "Never matches a numeric comparison when the record's value is nil" do
      ast = number_comparison(:comments, ">", 0)
      expect(evaluator.matches?(ast, comments: nil)).to be false
    end

    it "Correctly matches != for a nil string record value against a non-blank literal" do
      ast = string_comparison(:title, "!=", "Ruby")
      expect(evaluator.matches?(ast, title: nil)).to be true
    end
  end
end
