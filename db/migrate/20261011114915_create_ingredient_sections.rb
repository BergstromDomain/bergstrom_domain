class CreateIngredientSections < ActiveRecord::Migration[8.1]
  def change
    # One headed ingredient list on a Recipe ("Meat sauce", "White sauce");
    # the heading is optional for a simple recipe's single list.
    create_table :ingredient_sections do |t|
      t.references :recipe,   null: false, foreign_key: true
      t.string     :heading
      t.integer    :position, null: false

      t.timestamps
    end
  end
end
