class CreatePersonMutes < ActiveRecord::Migration[8.1]
  def change
    create_table :person_mutes do |t|
      t.bigint :user_id,   null: false
      t.bigint :person_id, null: false

      t.timestamps
    end

    add_index :person_mutes, [ :user_id, :person_id ], unique: true
    add_foreign_key :person_mutes, :users
    add_foreign_key :person_mutes, :people
  end
end
