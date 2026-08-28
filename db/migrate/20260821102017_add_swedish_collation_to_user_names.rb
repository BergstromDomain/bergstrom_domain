class AddSwedishCollationToUserNames < ActiveRecord::Migration[8.1]
  # The "swedish" ICU collation already exists (created by
  # AddSwedishCollationToPeopleNames) and people.first_name/last_name still
  # depend on it — down must not drop it.
  def up
    change_column :users, :first_name, :string, null: false, default: "", collation: "swedish"
    change_column :users, :last_name,  :string, null: false, default: "", collation: "swedish"
  end

  def down
    change_column :users, :first_name, :string, null: false, default: ""
    change_column :users, :last_name,  :string, null: false, default: ""
  end
end
