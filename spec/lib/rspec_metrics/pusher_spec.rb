# spec/lib/rspec_metrics/pusher_spec.rb
require "rails_helper"

RSpec.describe RspecMetrics::Pusher do
  around do |example|
    Dir.mktmpdir do |dir|
      @summary_path = File.join(dir, "summary.json")
      example.run
    end
  end

  def write_summary(rows)
    File.write(@summary_path, JSON.generate(rows))
  end

  def with_env(vars)
    original = vars.keys.to_h { |key| [ key, ENV[key] ] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  let(:required_env) do
    {
      "GRAFANA_CLOUD_PUSH_URL" => "https://example.grafana.net/api/v1/push/influx/write",
      "GRAFANA_CLOUD_INSTANCE_ID" => "12345",
      "GRAFANA_CLOUD_API_TOKEN" => "secret-token",
      "RSPEC_METRICS_BRANCH" => "main",
      "RSPEC_METRICS_COMMIT_SHA" => "abc1234"
    }
  end

  def stub_http_success
    response = instance_double(Net::HTTPOK, is_a?: true, code: "204", message: "No Content")
    http = instance_double(Net::HTTP, request: response)
    allow(Net::HTTP).to receive(:start).and_yield(http)
    http
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Builds a correctly formatted Line Protocol payload and POSTs it with Basic Auth" do
      write_summary([
        { spec_type: "Model", app: "Event_Tracker", flow: "Happy Path", passed: 11, failed: 0, pending: 1 }
      ])
      http = stub_http_success

      with_env(required_env) do
        result = described_class.call(summary_path: @summary_path)
        expect(result).to eq(:pushed)
      end

      expect(Net::HTTP).to have_received(:start).with("example.grafana.net", 443, hash_including(use_ssl: true))
      expect(http).to have_received(:request) do |request|
        expect(request.body).to eq(
          "rspec_examples,app=Event_Tracker,branch=main,commit_sha=abc1234,flow=Happy\\ Path,source=ci,spec_type=Model " \
          "passed=11i,failed=0i,pending=1i"
        )
      end
    end

    it "Joins multiple summary rows as separate lines" do
      write_summary([
        { spec_type: "Model", app: "Main", flow: nil, passed: 5, failed: 0, pending: 0 },
        { spec_type: "Feature", app: "Blog_Posts", flow: "Edge Cases", passed: 2, failed: 1, pending: 0 }
      ])
      http = stub_http_success

      with_env(required_env) do
        described_class.call(summary_path: @summary_path)
      end

      expect(http).to have_received(:request) do |request|
        expect(request.body.lines.count).to eq(2)
      end
    end
  end

  # 2) Negative Path ────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Raises MissingCredentialsError when a required env var is absent, and makes no HTTP call" do
      write_summary([ { spec_type: "Model", app: "Main", flow: nil, passed: 1, failed: 0, pending: 0 } ])
      allow(Net::HTTP).to receive(:start)

      incomplete_env = required_env.merge("GRAFANA_CLOUD_API_TOKEN" => nil)
      with_env(incomplete_env) do
        expect { described_class.call(summary_path: @summary_path) }
          .to raise_error(RspecMetrics::Pusher::MissingCredentialsError, /GRAFANA_CLOUD_API_TOKEN/)
      end

      expect(Net::HTTP).not_to have_received(:start)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Returns :skipped and makes no HTTP call when the summary file does not exist" do
      allow(Net::HTTP).to receive(:start)
      missing_path = File.join(File.dirname(@summary_path), "does_not_exist.json")

      with_env(required_env) do
        expect(described_class.call(summary_path: missing_path)).to eq(:skipped)
      end

      expect(Net::HTTP).not_to have_received(:start)
    end

    it "Returns :skipped and makes no HTTP call when the summary file is an empty array" do
      write_summary([])
      allow(Net::HTTP).to receive(:start)

      with_env(required_env) do
        expect(described_class.call(summary_path: @summary_path)).to eq(:skipped)
      end

      expect(Net::HTTP).not_to have_received(:start)
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Returns :failed and warns when Grafana Cloud responds with a non-success status" do
      write_summary([ { spec_type: "Model", app: "Main", flow: nil, passed: 1, failed: 0, pending: 0 } ])
      response = instance_double(Net::HTTPBadRequest, is_a?: false, code: "400", message: "Bad Request")
      http = instance_double(Net::HTTP, request: response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      result = nil
      expect {
        with_env(required_env) { result = described_class.call(summary_path: @summary_path) }
      }.to output(/push failed with 400/).to_stderr

      expect(result).to eq(:failed)
    end

    it "Escapes special characters in tag values and omits a nil flow tag entirely" do
      write_summary([
        { spec_type: "Model", app: "Main", flow: nil, passed: 1, failed: 0, pending: 0 }
      ])
      http = stub_http_success

      with_env(required_env) do
        described_class.call(summary_path: @summary_path)
      end

      expect(http).to have_received(:request) do |request|
        expect(request.body).not_to include("flow=")
      end
    end
  end
end
