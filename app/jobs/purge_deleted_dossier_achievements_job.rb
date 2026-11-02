# app/jobs/purge_deleted_dossier_achievements_job.rb
class PurgeDeletedDossierAchievementsJob < ApplicationJob
  queue_as :default

  def perform
    Dossier::Achievement.discarded.where(deleted_at: ..Dossier::Achievement::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
