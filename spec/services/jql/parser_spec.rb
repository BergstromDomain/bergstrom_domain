# spec/services/jql/parser_spec.rb

require "rails_helper"

RSpec.describe Jql::Parser do
  def comparison(field:, operator:, value:, value_type:)
    Jql::Parser::Comparison.new(field: field, operator: operator, value: value, value_type: value_type)
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Parses a simple string equality comparison" do
      ast = described_class.parse('title = "Hello"')
      expect(ast).to eq(comparison(field: :title, operator: "=", value: "Hello", value_type: :string))
    end

    it "Parses each comparison operator" do
      %w[= != > < >= <=].each do |operator|
        ast = described_class.parse("comments #{operator} 5")
        expect(ast.operator).to eq(operator)
      end
    end

    it "Parses a CONTAINS comparison" do
      ast = described_class.parse('title CONTAINS "rails"')
      expect(ast).to eq(comparison(field: :title, operator: "CONTAINS", value: "rails", value_type: :string))
    end

    it "Parses a numeric literal with a decimal point" do
      ast = described_class.parse("smiles >= 3.5")
      expect(ast.value).to eq(3.5)
    end

    it "Parses an AND of two comparisons" do
      ast = described_class.parse('category = "Food" AND comments > 1')
      expect(ast).to be_a(Jql::Parser::And)
      expect(ast.left.field).to eq(:category)
      expect(ast.right.field).to eq(:comments)
    end

    it "Parses an OR of two comparisons" do
      ast = described_class.parse('category = "Food" OR category = "Technology"')
      expect(ast).to be_a(Jql::Parser::Or)
    end

    it "Parses parentheses for grouping" do
      ast = described_class.parse('(category = "Food")')
      expect(ast).to eq(comparison(field: :category, operator: "=", value: "Food", value_type: :string))
    end

    it "Is tolerant of extra whitespace" do
      ast = described_class.parse('  title   =    "Hello"  ')
      expect(ast).to eq(comparison(field: :title, operator: "=", value: "Hello", value_type: :string))
    end

    it "Treats AND/OR/CONTAINS keywords as case-insensitive" do
      ast = described_class.parse('category = "Food" and comments > 1')
      expect(ast).to be_a(Jql::Parser::And)

      ast = described_class.parse('title contains "rails"')
      expect(ast.operator).to eq("CONTAINS")
    end

    it "Unescapes a backslash-escaped quote inside a string literal" do
      ast = described_class.parse('title = "She said \\"hi\\""')
      expect(ast.value).to eq('She said "hi"')
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Raises on a blank query" do
      expect { described_class.parse("") }.to raise_error(Jql::ParseError, /cannot be blank/)
    end

    it "Raises on an unbalanced opening parenthesis" do
      expect { described_class.parse('(category = "Food"') }.to raise_error(Jql::ParseError, /closing/)
    end

    it "Raises on an unexpected closing parenthesis" do
      expect { described_class.parse('category = "Food")') }.to raise_error(Jql::ParseError)
    end

    it "Raises when a comparison is missing its value" do
      expect { described_class.parse("category =") }.to raise_error(Jql::ParseError, /value/)
    end

    it "Raises on trailing garbage after a valid expression" do
      expect { described_class.parse('category = "Food" bogus') }.to raise_error(Jql::ParseError)
    end

    it "Raises on two adjacent string literals instead of silently concatenating them" do
      expect { described_class.parse('title = "Foo" "Bar"') }.to raise_error(Jql::ParseError)
    end

    it "Raises on an unrecognized character" do
      expect { described_class.parse("category = @Food") }.to raise_error(Jql::ParseError, /Unexpected character/)
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Binds AND tighter than OR (a AND b OR c reads as (a AND b) OR c)" do
      ast = described_class.parse('category = "Food" AND comments > 1 OR topic = "Ruby"')

      expect(ast).to be_a(Jql::Parser::Or)
      expect(ast.left).to be_a(Jql::Parser::And)
      expect(ast.left.left.field).to eq(:category)
      expect(ast.left.right.field).to eq(:comments)
      expect(ast.right.field).to eq(:topic)
    end

    it "Lets parentheses override the default precedence" do
      ast = described_class.parse('category = "Food" AND (comments > 1 OR topic = "Ruby")')

      expect(ast).to be_a(Jql::Parser::And)
      expect(ast.right).to be_a(Jql::Parser::Or)
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Handles deeply nested parentheses" do
      ast = described_class.parse('((((category = "Food"))))')
      expect(ast).to eq(comparison(field: :category, operator: "=", value: "Food", value_type: :string))
    end

    it "Parses a bare integer literal without a decimal point as an Integer" do
      ast = described_class.parse("comments = 5")
      expect(ast.value).to eq(5)
      expect(ast.value).to be_an(Integer)
    end

    it "Lowercases field names regardless of the input casing" do
      ast = described_class.parse('CATEGORY = "Food"')
      expect(ast.field).to eq(:category)
    end
  end
end
