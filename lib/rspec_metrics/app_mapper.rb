# lib/rspec_metrics/app_mapper.rb
module RspecMetrics
  # Maps a spec file path to the stable internal app identifier (Main,
  # Event_Tracker, Blog_Posts, ...) used to tag pushed test-result metrics.
  # Display/brand names (Occasions, Chronicle) are applied later, at the
  # Grafana panel level, not here — see Feature_-_Test_Result_Dashboard.md
  # decision #5 for why.
  class AppMapper
    UnmappedSpecError = Class.new(StandardError)

    # Exact-path overrides checked before the topic-based lookup below.
    OVERRIDES = {
      "spec/features/settings/chronicle_settings_spec.rb" => "Blog_Posts",
      "spec/features/settings/occasions_settings_spec.rb" => "Event_Tracker"
    }.freeze

    TOPICS_BY_APP = {
      "Event_Tracker" => %w[
        events event_types export import people social_media_platforms
        event_mute event_person event event_type_mute event_type person_mute
        person_social_media_account person social_media_platform
        events_mutes event_types_mutes people_mutes export_service import_service
      ],
      "Blog_Posts" => %w[
        blog_categories blog_posts blog_category blog_post_author blog_post
        comment like blog_post_export_service blog_post_filter jql
      ],
      "Main" => %w[
        auth contacts layouts pages settings shared system_admin
        app_permission contact policy user_app_setting user concerns
        footer build_info_service rspec_metrics
      ]
    }.freeze

    TOPIC_TO_APP = TOPICS_BY_APP.each_with_object({}) do |(app, topics), lookup|
      topics.each { |topic| lookup[topic] = app }
    end.freeze

    SPEC_TYPE_BY_DIR = {
      "features" => "Feature",
      "models" => "Model",
      "requests" => "Request",
      "services" => "Service",
      "views" => "View",
      "lib" => "Lib"
    }.freeze

    def self.app_for(spec_file_path)
      new(spec_file_path).app
    end

    def self.spec_type_for(spec_file_path)
      new(spec_file_path).spec_type
    end

    def initialize(spec_file_path)
      @path = spec_file_path.to_s.sub(%r{\A\./}, "")
    end

    def app
      OVERRIDES[@path] || TOPIC_TO_APP[topic] || raise(UnmappedSpecError, "No app mapping for #{@path.inspect}")
    end

    def spec_type
      SPEC_TYPE_BY_DIR[spec_type_dir] || raise(UnmappedSpecError, "No spec_type mapping for #{@path.inspect}")
    end

    private

    def spec_type_dir
      @path.split("/")[1]
    end

    def topic
      remainder = @path.split("/")[2..] || []

      if remainder.size >= 2
        remainder.first
      else
        remainder.first.to_s.sub(/_spec\.rb\z/, "")
      end
    end
  end
end
