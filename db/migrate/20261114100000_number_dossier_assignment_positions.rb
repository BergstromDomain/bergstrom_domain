# db/migrate/20261114100000_number_dossier_assignment_positions.rb

# Dossier: an Assignment's hand-made place within its Engagement. The column
# came with the table but was never used (all nil). Existing Assignments are
# numbered in the order the Timeline showed them: latest end first, a month
# end counting as the month's last day and a current one as today, so
# nothing moves until it's re-sorted.
class NumberDossierAssignmentPositions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE dossier_assignments
      SET position = numbered.row_number
      FROM (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY engagement_id
          ORDER BY COALESCE(CASE end_precision
                              WHEN 'month' THEN (date_trunc('month', end_on) + interval '1 month - 1 day')::date
                              WHEN 'year'  THEN (date_trunc('year', end_on) + interval '1 year - 1 day')::date
                              ELSE end_on
                            END, CURRENT_DATE) DESC,
                   start_on DESC, id DESC
        ) AS row_number
        FROM dossier_assignments
      ) AS numbered
      WHERE dossier_assignments.id = numbered.id
    SQL
    change_column_null :dossier_assignments, :position, false
    add_index :dossier_assignments, [ :engagement_id, :position ]
  end

  def down
    remove_index :dossier_assignments, [ :engagement_id, :position ]
    change_column_null :dossier_assignments, :position, true
    execute "UPDATE dossier_assignments SET position = NULL"
  end
end
