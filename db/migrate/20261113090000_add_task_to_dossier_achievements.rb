# db/migrate/20261113090000_add_task_to_dossier_achievements.rb

# An Achievement's Task, the T in STAR: private like its Situation, never on a CV.
class AddTaskToDossierAchievements < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_achievements, :task, :text
  end
end
