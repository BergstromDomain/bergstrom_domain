# db/migrate/YYYYMMDDHHMMSS_create_event_people.rb
class CreateEventPeople < ActiveRecord::Migration[8.0]
  def change
    create_table :event_people do |t|
      t.integer :event_id,  null: false
      t.integer :person_id, null: false

      t.timestamps
    end

    add_index :event_people, [ :event_id, :person_id ], unique: true
    add_foreign_key :event_people, :events
    add_foreign_key :event_people, :people
  end
end
