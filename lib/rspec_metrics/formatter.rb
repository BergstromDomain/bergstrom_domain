# lib/rspec_metrics/formatter.rb
module RspecMetrics
  # Custom RSpec formatter that walks the real example-group hierarchy (not
  # example.full_description string-parsing) to classify each example by
  # spec_type/app/flow, then writes an aggregated summary file for
  # lib/tasks/rspec_metrics.rake to push to Grafana Cloud. See
  # Feature_-_Test_Result_Dashboard.md decision #6.
  class Formatter
    RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending, :close

    FLOW_BUCKETS = [ "Happy Path", "Negative Path", "Alternative Paths", "Edge Cases" ].freeze

    def initialize(output)
      @output = output
      @counts = Hash.new { |hash, key| hash[key] = { passed: 0, failed: 0, pending: 0 } }
    end

    def example_passed(notification)
      record(notification.example, :passed)
    end

    def example_failed(notification)
      record(notification.example, :failed)
    end

    def example_pending(notification)
      record(notification.example, :pending)
    end

    def close(_notification)
      File.write(summary_path, JSON.generate(summary))
    end

    def summary
      @counts.map do |(spec_type, app, flow), counts|
        { spec_type: spec_type, app: app, flow: flow, **counts }
      end
    end

    private

    def record(example, status)
      file_path = example.metadata[:file_path]

      spec_type = RspecMetrics::AppMapper.spec_type_for(file_path)
      app = RspecMetrics::AppMapper.app_for(file_path)
      flow = flow_for(example)

      @counts[[ spec_type, app, flow ]][status] += 1
    rescue RspecMetrics::AppMapper::UnmappedSpecError => e
      warn("RspecMetrics::Formatter: #{e.message}, skipping")
    end

    def flow_for(example)
      example.example_group.parent_groups.map(&:description).find { |description| FLOW_BUCKETS.include?(description) }
    end

    def summary_path
      ENV.fetch("RSPEC_METRICS_SUMMARY_PATH") { Rails.root.join("tmp/rspec_metrics_summary.json").to_s }
    end
  end
end
