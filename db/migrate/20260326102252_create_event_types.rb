# db/migrate/YYYYMMDDHHMMSS_create_event_types.rb
class CreateEventTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :event_types do |t|
      t.string   :name,        null: false
      t.text     :description, null: false
      t.string   :icon,        null: false
      t.string   :slug

      t.timestamps
    end

    add_index :event_types, :name, unique: true
    add_index :event_types, :icon, unique: true
    add_index :event_types, :slug, unique: true
  end
end
