# spec/lib/rspec_metrics/app_mapper_spec.rb
require "rails_helper"

RSpec.describe RspecMetrics::AppMapper do
  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    context "Event_Tracker" do
      it "Maps a spec/features subdirectory topic" do
        expect(described_class.app_for("spec/features/events/events_by_week_spec.rb")).to eq("Event_Tracker")
      end

      it "Maps a flat spec/models file topic" do
        expect(described_class.app_for("spec/models/person_spec.rb")).to eq("Event_Tracker")
      end

      it "Maps a flat spec/requests file topic" do
        expect(described_class.app_for("spec/requests/events_mutes_spec.rb")).to eq("Event_Tracker")
      end

      it "Maps a flat spec/services file topic" do
        expect(described_class.app_for("spec/services/export_service_spec.rb")).to eq("Event_Tracker")
      end
    end

    context "Blog_Posts" do
      it "Maps a spec/features subdirectory topic" do
        expect(described_class.app_for("spec/features/blog_posts/create_blog_post_spec.rb")).to eq("Blog_Posts")
      end

      it "Maps a flat spec/models file topic" do
        expect(described_class.app_for("spec/models/comment_spec.rb")).to eq("Blog_Posts")
      end

      it "Maps the jql services subdirectory topic" do
        expect(described_class.app_for("spec/services/jql/evaluator_spec.rb")).to eq("Blog_Posts")
      end
    end

    context "Main" do
      it "Maps a spec/features subdirectory topic" do
        expect(described_class.app_for("spec/features/auth/sign_in_spec.rb")).to eq("Main")
      end

      it "Maps a flat spec/models file topic" do
        expect(described_class.app_for("spec/models/policy_spec.rb")).to eq("Main")
      end

      it "Maps the spec/models/concerns subdirectory topic" do
        expect(described_class.app_for("spec/models/concerns/roleable_spec.rb")).to eq("Main")
      end

      it "Maps the spec/requests/system_admin subdirectory topic" do
        expect(described_class.app_for("spec/requests/system_admin/users_spec.rb")).to eq("Main")
      end

      it "Maps a spec/views subdirectory topic" do
        expect(described_class.app_for("spec/views/shared/_toast.html.erb_spec.rb")).to eq("Main")
      end
    end

    context "settings/ file-level overrides" do
      it "Maps chronicle_settings_spec.rb to Blog_Posts, not the Main directory default" do
        expect(described_class.app_for("spec/features/settings/chronicle_settings_spec.rb")).to eq("Blog_Posts")
      end

      it "Maps occasions_settings_spec.rb to Event_Tracker, not the Main directory default" do
        expect(described_class.app_for("spec/features/settings/occasions_settings_spec.rb")).to eq("Event_Tracker")
      end
    end

    context "spec_type_for" do
      it "Maps each spec-type directory to its singular Title Case name" do
        expect(described_class.spec_type_for("spec/features/events/events_by_week_spec.rb")).to eq("Feature")
        expect(described_class.spec_type_for("spec/models/person_spec.rb")).to eq("Model")
        expect(described_class.spec_type_for("spec/requests/contacts_spec.rb")).to eq("Request")
        expect(described_class.spec_type_for("spec/services/export_service_spec.rb")).to eq("Service")
        expect(described_class.spec_type_for("spec/views/shared/_toast.html.erb_spec.rb")).to eq("View")
      end
    end
  end

  # 2) Negative Path ────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Raises a clear error for a path with no known topic mapping" do
      expect { described_class.app_for("spec/models/some_future_model_spec.rb") }
        .to raise_error(RspecMetrics::AppMapper::UnmappedSpecError, /some_future_model/)
    end

    it "Raises a clear error for spec_type_for given an unrecognised spec-type directory" do
      expect { described_class.spec_type_for("spec/jobs/some_job_spec.rb") }
        .to raise_error(RspecMetrics::AppMapper::UnmappedSpecError, /jobs/)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Accepts a path with a leading './' as RSpec's own file_path values have" do
      expect(described_class.app_for("./spec/models/person_spec.rb")).to eq("Event_Tracker")
    end

    it "Accepts a Pathname as well as a String" do
      expect(described_class.app_for(Pathname.new("spec/models/person_spec.rb"))).to eq("Event_Tracker")
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Falls back to the settings/ directory default (Main) for a file with no explicit override" do
      expect(described_class.app_for("spec/features/settings/preferences_spec.rb")).to eq("Main")
    end

    it "Correctly derives the topic from an .html.erb_spec.rb view spec filename" do
      expect(described_class.app_for("spec/views/layouts/_footer.html.erb_spec.rb")).to eq("Main")
    end
  end
end
