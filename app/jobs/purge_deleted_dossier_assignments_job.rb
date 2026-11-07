# app/jobs/purge_deleted_dossier_assignments_job.rb
class PurgeDeletedDossierAssignmentsJob < ApplicationJob
  queue_as :default

  # Destroying an Assignment destroys its Achievements; its Training moves up
  # to the Engagement.
  def perform
    Dossier::Assignment.discarded.where(deleted_at: ..Dossier::Assignment::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
