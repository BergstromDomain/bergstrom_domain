# app/services/jql/evaluator.rb
module Jql
  # Validates and evaluates a Jql::Parser AST against a caller-supplied
  # field-type schema (e.g. { title: :string, comments: :integer }) and plain
  # Ruby record hashes ({ title: "...", comments: 3 }). Has no knowledge of
  # where the schema or records come from — BlogPostFilter is the only place
  # in this app that knows about BlogPost specifically.
  #
  # Contract: call #validate! once per parsed query, before ever calling
  # #matches? — validation is what catches an unknown field, a numeric
  # operator used on a text field, or an unparseable date, all with a single
  # friendly Jql::ParseError up front rather than a confusing failure deep
  # inside per-record evaluation.
  class Evaluator
    STRING_OPERATORS  = %w[= != CONTAINS].freeze
    ORDERED_OPERATORS = %w[= != > < >= <=].freeze
    BOOLEAN_OPERATORS = %w[= !=].freeze

    def initialize(schema)
      @schema = schema
    end

    def validate!(ast)
      each_comparison(ast) { |node| validate_comparison!(node) }
      true
    end

    def matches?(ast, record)
      case ast
      when Parser::And        then matches?(ast.left, record) && matches?(ast.right, record)
      when Parser::Or         then matches?(ast.left, record) || matches?(ast.right, record)
      when Parser::Comparison then evaluate_comparison(ast, record)
      else
        raise ArgumentError, "Unknown AST node: #{ast.class}"
      end
    end

    private

    def each_comparison(ast, &block)
      case ast
      when Parser::And, Parser::Or
        each_comparison(ast.left, &block)
        each_comparison(ast.right, &block)
      when Parser::Comparison
        block.call(ast)
      else
        raise ArgumentError, "Unknown AST node: #{ast.class}"
      end
    end

    def validate_comparison!(node)
      type = @schema[node.field]
      unless type
        raise ParseError, "Unknown field '#{node.field}'. Valid fields: #{@schema.keys.join(', ')}."
      end

      if type == :string
        validate_string_comparison!(node)
      elsif type == :boolean
        validate_boolean_comparison!(node)
      else
        validate_ordered_comparison!(node, type)
      end
    end

    def validate_boolean_comparison!(node)
      unless BOOLEAN_OPERATORS.include?(node.operator)
        raise ParseError, "Operator '#{node.operator}' is not valid for boolean field '#{node.field}'. Use = or !=."
      end
      unless node.value_type == :string && %w[true false].include?(node.value.downcase)
        raise ParseError, "Field '#{node.field}' expects true or false."
      end
    end

    def validate_string_comparison!(node)
      unless STRING_OPERATORS.include?(node.operator)
        raise ParseError,
          "Operator '#{node.operator}' is not valid for text field '#{node.field}'. Use =, !=, or CONTAINS."
      end
      unless node.value_type == :string
        raise ParseError, "Field '#{node.field}' expects text, not a number."
      end
    end

    def validate_ordered_comparison!(node, type)
      unless ORDERED_OPERATORS.include?(node.operator)
        raise ParseError, "'CONTAINS' can only be used with a text field, not '#{node.field}'."
      end

      if type == :date
        unless node.value_type == :string
          raise ParseError, "Field '#{node.field}' expects a date (e.g. \"2026-01-01\")."
        end
        coerce_date(node)
      elsif node.value_type != :number
        raise ParseError, "Field '#{node.field}' expects a number."
      end
    end

    def coerce_date(node)
      Date.parse(node.value)
    rescue ArgumentError, TypeError
      raise ParseError, "Invalid date #{node.value.inspect} for field '#{node.field}'."
    end

    def evaluate_comparison(node, record)
      type = @schema.fetch(node.field)
      actual = record[node.field]

      case type
      when :string
        evaluate_string(node.operator, actual.to_s, node.value)
      when :date
        return false if actual.nil?
        compare(node.operator, actual.to_date, coerce_date(node))
      when :boolean
        return false if actual.nil?
        compare(node.operator, actual, node.value.downcase == "true")
      else
        return false if actual.nil?
        compare(node.operator, actual, node.value)
      end
    end

    def evaluate_string(operator, actual, value)
      case operator
      when "="        then actual.casecmp?(value)
      when "!="       then !actual.casecmp?(value)
      when "CONTAINS" then actual.downcase.include?(value.downcase)
      end
    end

    def compare(operator, actual, value)
      case operator
      when "="  then actual == value
      when "!=" then actual != value
      when ">"  then actual > value
      when "<"  then actual < value
      when ">=" then actual >= value
      when "<=" then actual <= value
      end
    end
  end
end
