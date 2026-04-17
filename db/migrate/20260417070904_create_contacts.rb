# db/migrate/TIMESTAMP_create_contacts.rb
class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.bigint :user_id,    null: false
      t.bigint :contact_id, null: false
      t.string :status,     null: false, default: "pending"

      t.timestamps
    end

    add_index :contacts, [ :user_id, :contact_id ], unique: true
    add_foreign_key :contacts, :users, column: :user_id
    add_foreign_key :contacts, :users, column: :contact_id
  end
end
