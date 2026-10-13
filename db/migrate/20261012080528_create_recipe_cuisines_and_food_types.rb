# A recipe has one or two Cuisines and one or two Food Types (Swedish lasagna:
# Swedish + Italian, Pasta + Mince Meat) — see Block 8 in
# docs/context-prompts/active/Cookbook_App.md. `position` 0 is the primary one.
class CreateRecipeCuisinesAndFoodTypes < ActiveRecord::Migration[8.1]
  def up
    create_table :recipe_cuisines do |t|
      t.references :recipe,   null: false, foreign_key: true
      t.references :cuisine,  null: false, foreign_key: true
      t.integer    :position, null: false

      t.timestamps
    end
    add_index :recipe_cuisines, [ :recipe_id, :cuisine_id ], unique: true

    create_table :recipe_food_types do |t|
      t.references :recipe,    null: false, foreign_key: true
      t.references :food_type, null: false, foreign_key: true
      t.integer    :position,  null: false

      t.timestamps
    end
    add_index :recipe_food_types, [ :recipe_id, :food_type_id ], unique: true

    execute <<~SQL
      INSERT INTO recipe_cuisines (recipe_id, cuisine_id, position, created_at, updated_at)
      SELECT id, cuisine_id, 0, NOW(), NOW() FROM recipes;
      INSERT INTO recipe_food_types (recipe_id, food_type_id, position, created_at, updated_at)
      SELECT id, food_type_id, 0, NOW(), NOW() FROM recipes;
    SQL

    remove_reference :recipes, :cuisine,   foreign_key: true, index: true
    remove_reference :recipes, :food_type, foreign_key: true, index: true
  end

  # Keeps only each recipe's primary Cuisine and Food Type.
  def down
    add_reference :recipes, :cuisine,   foreign_key: true
    add_reference :recipes, :food_type, foreign_key: true

    execute <<~SQL
      UPDATE recipes SET cuisine_id = rc.cuisine_id
        FROM recipe_cuisines rc WHERE rc.recipe_id = recipes.id AND rc.position = 0;
      UPDATE recipes SET food_type_id = rft.food_type_id
        FROM recipe_food_types rft WHERE rft.recipe_id = recipes.id AND rft.position = 0;
    SQL

    change_column_null :recipes, :cuisine_id,   false
    change_column_null :recipes, :food_type_id, false

    drop_table :recipe_food_types
    drop_table :recipe_cuisines
  end
end
