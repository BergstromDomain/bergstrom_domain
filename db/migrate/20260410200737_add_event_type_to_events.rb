# db/migrate/YYYYMMDDHHMMSS_add_event_type_to_events.rb
class AddEventTypeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :event_type_id, :integer
    add_foreign_key :events, :event_types
    add_index :events, :event_type_id
  end
end
