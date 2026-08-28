class AddDefaultClassificationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :default_classifications, :string, array: true,
               default: %w[unrestricted contacts restricted], null: false
  end
end
