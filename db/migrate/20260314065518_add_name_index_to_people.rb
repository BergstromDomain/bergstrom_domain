class AddNameIndexToPeople < ActiveRecord::Migration[8.0]
  def change
    add_index :people, [ :firstname, :lastname ], unique: true
  end
end
