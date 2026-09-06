# app/services/build_info_service.rb
require "open3"

# Reads build metadata (version, git SHA, build date) for the site footer.
#
# In a built/deployed context these come from a generated build-info file
# (see lib/tasks/build_info.rake) that doesn't depend on .git being present
# in the running artifact. In local development, where no build-info file
# has been generated, each field falls back independently to the VERSION
# file and/or a local git command.
class BuildInfoService
  DEFAULT_BUILD_INFO_PATH = Rails.root.join("config/build_info.yml")
  DEFAULT_VERSION_PATH = Rails.root.join("VERSION")

  def initialize(build_info_path: DEFAULT_BUILD_INFO_PATH, version_path: DEFAULT_VERSION_PATH)
    @build_info_path = build_info_path
    @version_path = version_path
    @build_info = load_build_info
  end

  def version
    @build_info&.dig("version") || read_version_file
  end

  def git_sha
    @build_info&.dig("git_sha") || capture_git("rev-parse", "--short", "HEAD")
  end

  def build_date
    @build_info&.dig("build_date") || capture_git("log", "-1", "--format=%cd", "--date=short")
  end

  private

  def load_build_info
    return nil unless File.exist?(@build_info_path)

    YAML.safe_load_file(@build_info_path)
  rescue Psych::SyntaxError
    nil
  end

  def read_version_file
    return nil unless File.exist?(@version_path)

    File.read(@version_path).strip
  end

  def capture_git(*args)
    stdout, status = Open3.capture2("git", *args, chdir: Rails.root)
    stdout.strip if status.success?
  rescue Errno::ENOENT
    nil
  end
end
