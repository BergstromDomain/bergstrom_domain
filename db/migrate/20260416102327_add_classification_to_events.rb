# db/migrate/YYYYMMDDHHMMSS_add_classification_to_events.rb
class AddClassificationToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :classification, :string, null: false, default: "contacts"
  end
end
