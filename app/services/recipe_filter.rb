# app/services/recipe_filter.rb

# Cookbook's Filter Recipes fields on the shared Jql engine — the Recipe
# counterpart of BlogPostFilter. Cuisine, Food Type and ingredients are
# lists (a recipe has one or two of each, and many ingredients), which
# Jql::Evaluator matches when any value does.
class RecipeFilter
  FIELD_SCHEMA = {
    cuisine:     :string,
    food_type:   :string,
    language:    :string,
    title:       :string,
    chef:        :string,
    cook_time:   :string,
    created:     :date,
    portions:    :integer,
    serves:      :integer,
    makes:       :integer,
    comments:    :integer,
    reactions:   :decimal,
    published:   :boolean,
    ingredients: :string
  }.freeze

  EVALUATOR = Jql::Evaluator.new(FIELD_SCHEMA)

  # What each field reads beyond the recipe's own columns, so a page loads
  # only what its query and sort column use (see .preload).
  ASSOCIATIONS = {
    cuisine:     :cuisines,
    food_type:   :food_types,
    language:    :language,
    chef:        :user,
    reactions:   :likes,
    ingredients: { ingredient_sections: :ingredients }
  }.freeze

  def self.attribute(recipe, field)
    case field
    when :cuisine     then recipe.cuisines.map(&:name)
    when :food_type   then recipe.food_types.map(&:name)
    when :language    then recipe.language.name
    when :title       then recipe.title
    when :chef        then "#{recipe.user.first_name} #{recipe.user.last_name}"
    when :cook_time   then recipe.cook_time
    when :created     then recipe.created_at
    when :portions    then recipe.portions.last
    when :serves      then recipe.serves
    when :makes       then recipe.makes
    when :comments    then recipe.comments_count
    when :reactions   then recipe.like_score
    when :published   then recipe.published?
    when :ingredients then recipe.ingredient_sections.flat_map(&:ingredients).map(&:name)
    end
  end

  # Built on demand, so evaluating a query only touches the fields it names.
  def self.attributes_for(recipe)
    Hash.new { |attrs, field| attrs[field] = attribute(recipe, field) }
  end

  def self.preload(recipes, fields)
    associations = fields.filter_map { |field| ASSOCIATIONS[field.to_sym] }
    return if associations.empty?

    ActiveRecord::Associations::Preloader.new(records: recipes, associations: associations).call
  end

  # Builds an AND of whichever filters are present; returns nil ("no filter,
  # show everything") when every argument is blank. `published` is "true"/
  # "false"/nil (nil means "All", not part of the filter at all).
  def self.basic_ast(cuisine: nil, food_type: nil, language: nil, chef_name: nil, created_range: nil, published: nil)
    conditions = []
    conditions << string_comparison(:cuisine, cuisine) if cuisine.present?
    conditions << string_comparison(:food_type, food_type) if food_type.present?
    conditions << string_comparison(:language, language) if language.present?
    conditions << string_comparison(:chef, chef_name) if chef_name.present?
    conditions << string_comparison(:published, published) if published.present?

    if created_range
      conditions << date_comparison(:created, ">=", created_range.first)
      conditions << date_comparison(:created, "<=", created_range.last)
    end

    conditions.reduce { |left, right| Jql::Parser::And.new(left: left, right: right) }
  end

  # A list sorts by its first (primary) value. Nils sort last regardless of
  # direction.
  def self.sort(recipes, column, direction)
    field  = column.to_sym
    values = recipes.to_h { |recipe| [ recipe, Array.wrap(attribute(recipe, field)).first ] }
    with_nil, without_nil = recipes.partition { |recipe| values[recipe].nil? }

    sorted = without_nil.sort_by { |recipe| sort_key(values[recipe]) }
    sorted.reverse! if direction == "desc"
    sorted + with_nil
  end

  def self.string_comparison(field, value)
    Jql::Parser::Comparison.new(field: field, operator: "=", value: value, value_type: :string)
  end
  private_class_method :string_comparison

  def self.date_comparison(field, operator, date)
    Jql::Parser::Comparison.new(field: field, operator: operator, value: date.iso8601, value_type: :string)
  end
  private_class_method :date_comparison

  def self.sort_key(value)
    value.is_a?(String) ? value.downcase : value
  end
  private_class_method :sort_key
end
