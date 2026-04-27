# db/migrate/TIMESTAMP_add_user_to_people.rb
class AddUserToPeople < ActiveRecord::Migration[8.1]
  def up
    add_column :people, :user_id, :bigint

    first_user_id = User.order(:id).pick(:id)
    raise "No users exist — seed a user before running this migration" if first_user_id.nil?

    execute "UPDATE people SET user_id = #{first_user_id} WHERE user_id IS NULL"

    change_column_null :people, :user_id, false
    add_index :people, :user_id
    add_foreign_key :people, :users
  end

  def down
    remove_foreign_key :people, :users
    remove_index :people, :user_id
    remove_column :people, :user_id
  end
end
