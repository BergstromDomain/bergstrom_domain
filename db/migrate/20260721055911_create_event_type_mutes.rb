class CreateEventTypeMutes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_type_mutes do |t|
      t.bigint :user_id,       null: false
      t.bigint :event_type_id, null: false

      t.timestamps
    end

    add_index :event_type_mutes, [ :user_id, :event_type_id ], unique: true
    add_foreign_key :event_type_mutes, :users
    add_foreign_key :event_type_mutes, :event_types
  end
end
