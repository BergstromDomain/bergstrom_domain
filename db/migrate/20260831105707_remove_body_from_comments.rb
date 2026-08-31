class RemoveBodyFromComments < ActiveRecord::Migration[8.1]
  def change
    remove_column :comments, :body, :text
  end
end
