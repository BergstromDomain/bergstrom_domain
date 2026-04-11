# db/migrate/YYYYMMDDHHMMSS_make_event_type_id_not_null_on_events.rb
class MakeEventTypeIdNotNullOnEvents < ActiveRecord::Migration[8.0]
  def up
    # Ensure all events have an event_type before constraining
    raise "Some events are missing event_type_id — run db:seed:replant first" if Event.where(event_type_id: nil).exists?
    change_column_null :events, :event_type_id, false
  end

  def down
    change_column_null :events, :event_type_id, true
  end
end
