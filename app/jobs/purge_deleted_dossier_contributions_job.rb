# app/jobs/purge_deleted_dossier_contributions_job.rb
class PurgeDeletedDossierContributionsJob < ApplicationJob
  queue_as :default

  def perform
    Dossier::Contribution.discarded.where(deleted_at: ..Dossier::Contribution::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
