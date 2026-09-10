# spec/lib/rspec_metrics/formatter_spec.rb
require "rails_helper"

RSpec.describe RspecMetrics::Formatter do
  subject(:formatter) { described_class.new(StringIO.new) }

  def build_example(file_path:, group_descriptions:)
    groups = group_descriptions.map { |description| double("example_group", description: description) }
    example_group = double("example_group", parent_groups: groups)
    double("example", metadata: { file_path: file_path }, example_group: example_group)
  end

  def notification_for(example)
    double("notification", example: example)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Records a passed example under its spec_type/app/flow" do
      example = build_example(
        file_path: "spec/features/events/events_by_week_spec.rb",
        group_descriptions: [ "Happy Path", "Events By Week" ]
      )

      formatter.example_passed(notification_for(example))

      expect(formatter.summary).to contain_exactly(
        { spec_type: "Feature", app: "Event_Tracker", flow: "Happy Path", passed: 1, failed: 0, pending: 0 }
      )
    end

    it "Finds the flow bucket regardless of how deeply it's nested" do
      example = build_example(
        file_path: "spec/models/person_spec.rb",
        group_descriptions: [ "Happy Path", "Validations", "Person" ]
      )

      formatter.example_passed(notification_for(example))

      expect(formatter.summary.first).to include(spec_type: "Model", app: "Event_Tracker", flow: "Happy Path")
    end

    it "Aggregates multiple examples into the same bucket" do
      example = build_example(
        file_path: "spec/models/person_spec.rb",
        group_descriptions: [ "Happy Path", "Person" ]
      )

      2.times { formatter.example_passed(notification_for(example)) }

      expect(formatter.summary.first).to include(passed: 2)
    end

    it "Tracks passed/failed/pending as separate counts within the same bucket" do
      example = build_example(
        file_path: "spec/models/person_spec.rb",
        group_descriptions: [ "Happy Path", "Person" ]
      )

      formatter.example_passed(notification_for(example))
      formatter.example_failed(notification_for(example))
      formatter.example_pending(notification_for(example))
      formatter.example_pending(notification_for(example))

      expect(formatter.summary.first).to include(passed: 1, failed: 1, pending: 2)
    end
  end

  # 2) Negative Path ────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Skips an example whose file_path has no app mapping, without raising" do
      example = build_example(
        file_path: "spec/models/some_future_model_spec.rb",
        group_descriptions: [ "Some Future Model" ]
      )

      expect { formatter.example_passed(notification_for(example)) }
        .to output(/No app mapping/).to_stderr

      expect(formatter.summary).to be_empty
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Records flow: nil when no ancestor group matches a known flow bucket" do
      example = build_example(
        file_path: "spec/models/policy_spec.rb",
        group_descriptions: [ "unrestricted content", "#can_read?", "Policy" ]
      )

      formatter.example_passed(notification_for(example))

      expect(formatter.summary.first).to include(spec_type: "Model", app: "Main", flow: nil)
    end

    it "Writes the summary file via close, respecting the RSPEC_METRICS_SUMMARY_PATH override" do
      example = build_example(
        file_path: "spec/models/person_spec.rb",
        group_descriptions: [ "Happy Path", "Person" ]
      )
      formatter.example_passed(notification_for(example))

      Dir.mktmpdir do |dir|
        path = File.join(dir, "summary.json")
        original_path = ENV["RSPEC_METRICS_SUMMARY_PATH"]
        ENV["RSPEC_METRICS_SUMMARY_PATH"] = path

        begin
          formatter.close(double("notification"))
        ensure
          ENV["RSPEC_METRICS_SUMMARY_PATH"] = original_path
        end

        written = JSON.parse(File.read(path), symbolize_names: true)
        expect(written).to contain_exactly(
          { spec_type: "Model", app: "Event_Tracker", flow: "Happy Path", passed: 1, failed: 0, pending: 0 }
        )
      end
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Does not match a similarly-worded but non-exact group description" do
      example = build_example(
        file_path: "spec/models/person_spec.rb",
        group_descriptions: [ "happy path", "Person" ]
      )

      formatter.example_passed(notification_for(example))

      expect(formatter.summary.first).to include(flow: nil)
    end
  end
end
