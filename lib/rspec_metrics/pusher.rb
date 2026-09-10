# lib/rspec_metrics/pusher.rb
require "net/http"

module RspecMetrics
  # Reads the summary file written by RspecMetrics::Formatter and pushes it
  # to Grafana Cloud's InfluxDB Line Protocol HTTP endpoint. CI-only per
  # Feature_-_Test_Result_Dashboard.md decision #7 — branch/commit_sha come
  # from env vars the CI workflow sets (decision #9), not computed here, so
  # this class stays CI-agnostic and testable in isolation.
  class Pusher
    MissingCredentialsError = Class.new(StandardError)

    def self.call(summary_path: default_summary_path)
      new(summary_path: summary_path).call
    end

    def self.default_summary_path
      ENV.fetch("RSPEC_METRICS_SUMMARY_PATH") { Rails.root.join("tmp/rspec_metrics_summary.json").to_s }
    end

    def initialize(summary_path:)
      @summary_path = summary_path
    end

    def call
      return skip("no summary file at #{@summary_path}") unless File.exist?(@summary_path)

      rows = JSON.parse(File.read(@summary_path), symbolize_names: true)
      return skip("summary file is empty") if rows.empty?

      push(rows)
    end

    private

    def skip(reason)
      warn("RspecMetrics::Pusher: #{reason}, nothing to push")
      :skipped
    end

    def push(rows)
      # Resolve everything (including any missing-credential raise) before opening
      # the connection, so a config error never depends on Net::HTTP.start yielding.
      uri = URI.parse(push_url)
      body = payload(rows)
      auth = [ instance_id, api_token ]

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Post.new(uri)
        request.basic_auth(*auth)
        request["Content-Type"] = "text/plain"
        request.body = body
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        warn("RspecMetrics::Pusher: push failed with #{response.code} #{response.message}")
        return :failed
      end

      :pushed
    end

    def payload(rows)
      rows.map { |row| build_line(row) }.join("\n")
    end

    def build_line(row)
      tags = {
        "app" => row[:app],
        "branch" => branch,
        "commit_sha" => commit_sha,
        "source" => source,
        "spec_type" => row[:spec_type]
      }
      tags["flow"] = row[:flow] if row[:flow]

      tag_string = tags.sort.map { |key, value| "#{key}=#{escape(value)}" }.join(",")
      fields = "passed=#{row[:passed]}i,failed=#{row[:failed]}i,pending=#{row[:pending]}i"

      "rspec_examples,#{tag_string} #{fields}"
    end

    # Influx Line Protocol escaping — a backslash-escaped space/comma/equals is
    # wire-format encoding only; the value stored (and shown in Grafana) comes
    # back out as the natural, unescaped string, e.g. "Happy Path".
    def escape(value)
      value.to_s.gsub("\\", "\\\\\\\\").gsub(",", "\\,").gsub(" ", "\\ ").gsub("=", "\\=")
    end

    def push_url
      env_fetch("GRAFANA_CLOUD_PUSH_URL")
    end

    def instance_id
      env_fetch("GRAFANA_CLOUD_INSTANCE_ID")
    end

    def api_token
      env_fetch("GRAFANA_CLOUD_API_TOKEN")
    end

    def branch
      env_fetch("RSPEC_METRICS_BRANCH")
    end

    def commit_sha
      env_fetch("RSPEC_METRICS_COMMIT_SHA")
    end

    def source
      ENV.fetch("RSPEC_METRICS_SOURCE", "ci")
    end

    def env_fetch(key)
      ENV.fetch(key) { raise MissingCredentialsError, "#{key} not set" }
    end
  end
end
