# app/jobs/purge_deleted_recipes_job.rb
class PurgeDeletedRecipesJob < ApplicationJob
  queue_as :default

  def perform
    Recipe.discarded.where(deleted_at: ..Recipe::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
