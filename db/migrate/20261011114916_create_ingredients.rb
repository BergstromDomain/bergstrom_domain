class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    # Quantity is free text so "½", "2–3" and "a pinch" survive as typed.
    create_table :ingredients do |t|
      t.references :ingredient_section, null: false, foreign_key: true
      t.string     :quantity,    null: false
      t.string     :measurement
      t.string     :name,        null: false
      t.text       :comment
      t.integer    :position,    null: false

      t.timestamps
    end
  end
end
