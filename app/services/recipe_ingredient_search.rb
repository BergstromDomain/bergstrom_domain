# app/services/recipe_ingredient_search.rb

# Find Recipes By Ingredients (Block 10 in
# docs/context-prompts/archive/Cookbook_App.md): a recipe matches when every
# term appears, case-insensitively, somewhere inside one of its ingredient
# names. Matching runs in the database, one EXISTS per term, so the page
# never loads recipes it won't show.
class RecipeIngredientSearch
  MAX_TERMS = 10
  # A plural trimmed below this length would match almost anything.
  MIN_TRIMMED_LENGTH = 3

  attr_reader :terms

  def initialize(scope:, terms:)
    @scope = scope
    @terms = Array(terms).flat_map { |entry| entry.to_s.split(",") }
      .map(&:squish).compact_blank.uniq(&:downcase).first(MAX_TERMS)
  end

  # Recipes containing every term; none until a term is entered.
  def recipes
    return @scope.none if terms.empty?

    terms.reduce(@scope) { |relation, term| narrow(relation, term) }
  end

  # [[term, recipes left after it], ...], e.g. [["Chicken", 14], ["Garlic", 9]].
  def steps
    relation = @scope
    terms.map do |term|
      relation = narrow(relation, term)
      [ term, relation.count ]
    end
  end

  # The recipe's own ingredient names that matched, in recipe order.
  def matched_names(recipe)
    recipe.ingredient_sections.flat_map(&:ingredients).map(&:name).select do |name|
      terms.any? { |term| variants(term).any? { |variant| name.downcase.include?(variant) } }
    end
  end

  private

  def narrow(relation, term)
    patterns = variants(term).map { |variant| "%#{ActiveRecord::Base.sanitize_sql_like(variant)}%" }
    matching = Ingredient.joins(:ingredient_section)
      .where("ingredient_sections.recipe_id = recipes.id")
      .where(Ingredient.arel_table[:name].matches_any(patterns))

    relation.where(matching.arel.exists)
  end

  # "Tomatoes" also tries "tomatoe" and "tomato"; "eggs" also tries "egg".
  def variants(term)
    word = term.downcase
    trimmed = [ word.delete_suffix("es"), word.delete_suffix("s") ]
      .select { |variant| variant != word && variant.length >= MIN_TRIMMED_LENGTH }
    [ word, *trimmed ].uniq
  end
end
