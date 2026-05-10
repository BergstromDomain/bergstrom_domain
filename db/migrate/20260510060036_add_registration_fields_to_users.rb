class AddRegistrationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string, null: false, default: ""
    add_column :users, :last_name, :string, null: false, default: ""
    add_column :users, :status, :string, null: false, default: "pending"
    add_column :users, :message_to_admin, :text
    add_column :users, :email_verified_at, :datetime

    add_index :users, :status
  end
end
