class CreateEventMutes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_mutes do |t|
      t.bigint :user_id,  null: false
      t.bigint :event_id, null: false

      t.timestamps
    end

    add_index :event_mutes, [ :user_id, :event_id ], unique: true
    add_foreign_key :event_mutes, :users
    add_foreign_key :event_mutes, :events
  end
end
