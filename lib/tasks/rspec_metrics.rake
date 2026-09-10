# lib/tasks/rspec_metrics.rake
namespace :rspec_metrics do
  desc "Push the RSpec test-results summary (written by RspecMetrics::Formatter) to Grafana Cloud"
  task push: :environment do
    result = RspecMetrics::Pusher.call
    abort("rspec_metrics:push failed") if result == :failed
  end
end
