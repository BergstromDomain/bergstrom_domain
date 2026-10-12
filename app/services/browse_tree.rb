# app/services/browse_tree.rb

# App-agnostic drill-down over a scope, one level per URL param — e.g.
# Chronicle's Category › Subject › Topic. Zero knowledge of any one app (like
# Jql::Evaluator, PdfRenderingService, ZipBundlingService): callers describe
# their levels and pass in an already-visibility-scoped relation.
#
# The first level is a reference-data association: every record is listed,
# including ones with a zero count. It may be a belongs_to (a BlogPost's one
# Category) or a has_many (a Recipe's one or two Cuisines), in which case an
# item is counted and listed under each of its records. Later levels are optional string columns:
# only values that actually occur are listed, and blank values are never a
# child of their own — those items simply appear in the parent's `items`.
#
# Every selected level (depth > 0) exposes `items`: everything beneath it,
# newest first.
class BrowseTree
  # Association levels label each record via `label` (a method name,
  # default :name); column levels use the column's value as-is.
  Level = Struct.new(:key, :association, :records, :column, :label, keyword_init: true) do
    def association? = association.present?
    def label_for(record) = record.public_send(label || :name)
  end

  Node = Struct.new(:label, :count, :params, keyword_init: true)

  attr_reader :total_count, :path

  def initialize(scope:, levels:, params:)
    @scope       = scope
    @levels      = levels
    @total_count = scope.count
    @path        = []
    @invalid     = false
    resolve(params.to_h.symbolize_keys)
  end

  def depth = @path.size
  def leaf? = depth == @levels.size
  def invalid? = @invalid

  # Next level's entries, or nil at the leaf.
  def children
    return nil if leaf?

    level = @levels[depth]
    level.association? ? association_children(level) : column_children(level)
  end

  # Everything at the current level, newest first; nil at the root.
  def items
    return nil if depth.zero?

    @current_scope.order(created_at: :desc)
  end

  private

  def resolve(params)
    @current_scope = @scope
    selected = {}

    @levels.each do |level|
      value = params[level.key].presence
      break if value.nil?

      if level.association?
        record = find_record(level, value)
        return @invalid = true if record.nil?

        @current_scope = narrow_to(level, record)
        label = level.label_for(record)
        value = record.to_param
      else
        @current_scope = @current_scope.where(level.column => value)
        label = value
      end

      selected = selected.merge(level.key => value)
      @path << Node.new(label: label, count: @current_scope.count, params: selected)
    end
  end

  def find_record(level, value)
    records = level.records
    records.respond_to?(:friendly) ? records.friendly.find(value) : records.find_by(id: value)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def narrow_to(level, record)
    reflection = reflection_for(level)
    return @current_scope.where(level.association => record) unless reflection.collection?

    # A subquery rather than a join, so each item is listed once and the
    # scope stays free to be ordered or counted as usual.
    model = @scope.klass
    @current_scope.where(model.primary_key => model.joins(level.association)
      .where(reflection.table_name => { id: record.id }).select(model.primary_key))
  end

  def association_children(level)
    reflection = reflection_for(level)
    counts =
      if reflection.collection?
        @current_scope.joins(level.association).group("#{reflection.table_name}.id").count
      else
        @current_scope.group(reflection.foreign_key).count
      end

    level.records.map do |record|
      Node.new(label: level.label_for(record), count: counts.fetch(record.id, 0), params: child_params(level, record.to_param))
    end
  end

  def reflection_for(level)
    @scope.klass.reflect_on_association(level.association)
  end

  def column_children(level)
    @current_scope.where.not(level.column => [ nil, "" ]).group(level.column).count
      .sort_by { |value, _| value.downcase }
      .map { |value, count| Node.new(label: value, count: count, params: child_params(level, value)) }
  end

  def child_params(level, value)
    (@path.last&.params || {}).merge(level.key => value)
  end
end
