class AddSwedishCollationToPeopleNames < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE COLLATION IF NOT EXISTS swedish (provider = icu, locale = 'sv-SE');
    SQL

    change_column :people, :first_name, :string, null: false, collation: "swedish"
    change_column :people, :last_name,  :string,               collation: "swedish"
  end

  def down
    change_column :people, :first_name, :string, null: false
    change_column :people, :last_name,  :string

    execute "DROP COLLATION IF EXISTS swedish;"
  end
end
