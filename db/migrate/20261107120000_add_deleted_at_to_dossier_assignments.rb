# db/migrate/20261107120000_add_deleted_at_to_dossier_assignments.rb

# Deleting an Assignment becomes a soft delete, like Engagements and
# Achievements, so its Achievements can be restored for 30 days.
class AddDeletedAtToDossierAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_assignments, :deleted_at, :datetime
    add_index  :dossier_assignments, :deleted_at
  end
end
