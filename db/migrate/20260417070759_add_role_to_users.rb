# db/migrate/TIMESTAMP_add_role_to_users.rb
class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "app_user", null: false
  end
end
