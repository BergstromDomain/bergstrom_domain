# Dossier Block 2 — the project an Assignment was for ("Market Services"),
# so the Timeline can tell several Assignments for one client apart.
class AddProjectToDossierAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_assignments, :project, :string
  end
end
