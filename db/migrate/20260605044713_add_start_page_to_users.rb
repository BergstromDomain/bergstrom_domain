class AddStartPageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :start_page, :string, null: false, default: "home"
  end
end
