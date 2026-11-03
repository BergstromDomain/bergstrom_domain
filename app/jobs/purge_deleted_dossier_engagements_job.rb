# app/jobs/purge_deleted_dossier_engagements_job.rb
class PurgeDeletedDossierEngagementsJob < ApplicationJob
  queue_as :default

  # Destroying an Engagement destroys its Assignments and their Achievements.
  def perform
    Dossier::Engagement.discarded.where(deleted_at: ..Dossier::Engagement::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
