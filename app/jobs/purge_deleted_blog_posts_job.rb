# app/jobs/purge_deleted_blog_posts_job.rb
class PurgeDeletedBlogPostsJob < ApplicationJob
  queue_as :default

  def perform
    BlogPost.discarded.where(deleted_at: ..BlogPost::DELETION_RETENTION_PERIOD.ago).destroy_all
  end
end
