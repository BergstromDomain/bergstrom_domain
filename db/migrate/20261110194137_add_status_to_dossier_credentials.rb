# db/migrate/20261110194137_add_status_to_dossier_credentials.rb

# A Credential's status: todo, in_progress or completed. Existing rows follow
# their dates; a To Do Credential may have no Started date yet.
class AddStatusToDossierCredentials < ActiveRecord::Migration[8.1]
  def up
    add_column :dossier_credentials, :status, :string
    execute "UPDATE dossier_credentials SET status = CASE WHEN end_on IS NULL THEN 'in_progress' ELSE 'completed' END"
    change_column_null :dossier_credentials, :status, false
    change_column_null :dossier_credentials, :start_on, true
    add_index :dossier_credentials, [ :user_id, :status ]
  end

  def down
    execute "UPDATE dossier_credentials SET start_on = COALESCE(end_on, CURRENT_DATE) WHERE start_on IS NULL"
    change_column_null :dossier_credentials, :start_on, false
    remove_index :dossier_credentials, [ :user_id, :status ]
    remove_column :dossier_credentials, :status
  end
end
