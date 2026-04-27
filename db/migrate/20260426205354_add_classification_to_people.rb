# db/migrate/TIMESTAMP_add_classification_to_people.rb
class AddClassificationToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :classification, :string, null: false, default: "contacts"
  end
end
