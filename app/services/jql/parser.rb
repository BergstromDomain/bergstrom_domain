# app/services/jql/parser.rb
module Jql
  # A small, safe query language in the spirit of Jira's JQL: comparisons on
  # named fields combined with AND/OR and parentheses. This parser only knows
  # syntax — it has no idea what a field means semantically (that "created"
  # should be a date, say). Jql::Evaluator does all of that, against a
  # caller-supplied field-type schema, so this class carries zero domain
  # (BlogPost or otherwise) knowledge and is reusable as-is by a future app.
  #
  # Grammar:
  #   expression  := or_expr
  #   or_expr     := and_expr (OR and_expr)*
  #   and_expr    := unary (AND unary)*
  #   unary       := "(" expression ")" | comparison
  #   comparison  := FIELD OPERATOR VALUE
  #   OPERATOR    := "=" | "!=" | ">" | "<" | ">=" | "<=" | CONTAINS
  #   VALUE       := "quoted string" | 123 | 12.3
  class Parser
    Comparison = Struct.new(:field, :operator, :value, :value_type, keyword_init: true)
    And        = Struct.new(:left, :right, keyword_init: true)
    Or         = Struct.new(:left, :right, keyword_init: true)

    Token = Struct.new(:type, :value, keyword_init: true)

    def self.parse(text)
      new(text).parse
    end

    def initialize(text)
      @tokens = tokenize(text.to_s)
      @pos = 0
    end

    def parse
      raise ParseError, "Query cannot be blank." if @tokens.one?

      node = parse_or
      expect(:EOF)
      node
    end

    private

    def tokenize(text)
      tokens = []
      s = text.dup

      until s.empty?
        m =
          if (match = /\A\s+/.match(s))
            match
          elsif (match = /\A"((?:\\.|[^"\\])*)"/.match(s))
            tokens << Token.new(type: :STRING, value: match[1].gsub(/\\(.)/) { $1 })
            match
          elsif (match = /\A\d+(?:\.\d+)?/.match(s))
            raw = match[0]
            tokens << Token.new(type: :NUMBER, value: raw.include?(".") ? raw.to_f : raw.to_i)
            match
          elsif (match = /\A(!=|>=|<=|=|>|<)/.match(s))
            tokens << Token.new(type: :OPERATOR, value: match[1])
            match
          elsif (match = /\A\(/.match(s))
            tokens << Token.new(type: :LPAREN, value: "(")
            match
          elsif (match = /\A\)/.match(s))
            tokens << Token.new(type: :RPAREN, value: ")")
            match
          elsif (match = /\A[A-Za-z_][A-Za-z0-9_]*/.match(s))
            tokens << keyword_or_field_token(match[0])
            match
          else
            raise ParseError, "Unexpected character #{s[0].inspect} in query."
          end

        s = s[m[0].length..]
      end

      tokens << Token.new(type: :EOF, value: nil)
      tokens
    end

    def keyword_or_field_token(word)
      case word.upcase
      when "AND"      then Token.new(type: :AND, value: "AND")
      when "OR"       then Token.new(type: :OR, value: "OR")
      when "CONTAINS" then Token.new(type: :OPERATOR, value: "CONTAINS")
      else                 Token.new(type: :FIELD, value: word.downcase.to_sym)
      end
    end

    def current
      @tokens[@pos]
    end

    def advance
      token = current
      @pos += 1
      token
    end

    def expect(type, message = nil)
      unless current.type == type
        raise ParseError, message || "Unexpected token #{token_description(current)} (expected #{type})."
      end
      advance
    end

    def token_description(token)
      token.type == :EOF ? "end of query" : token.value.inspect
    end

    def parse_or
      node = parse_and
      while current.type == :OR
        advance
        node = Or.new(left: node, right: parse_and)
      end
      node
    end

    def parse_and
      node = parse_unary
      while current.type == :AND
        advance
        node = And.new(left: node, right: parse_unary)
      end
      node
    end

    def parse_unary
      if current.type == :LPAREN
        advance
        node = parse_or
        expect(:RPAREN, "Missing closing ')'.")
        node
      else
        parse_comparison
      end
    end

    def parse_comparison
      field_token = expect(:FIELD, "Expected a field name, got #{token_description(current)}.")
      operator_token = expect(:OPERATOR,
        "Expected an operator (=, !=, >, <, >=, <=, CONTAINS) after '#{field_token.value}'.")

      unless current.type == :STRING || current.type == :NUMBER
        raise ParseError, "Expected a value after '#{field_token.value} #{operator_token.value}'."
      end
      value_token = advance

      Comparison.new(
        field: field_token.value,
        operator: operator_token.value,
        value: value_token.value,
        value_type: value_token.type == :STRING ? :string : :number
      )
    end
  end
end
