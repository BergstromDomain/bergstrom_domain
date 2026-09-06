# lib/tasks/build_info.rake
namespace :build_info do
  desc "Generate config/build_info.yml with the current version, git SHA, and build date"
  task generate: :environment do
    require "open3"

    version = File.read(Rails.root.join("VERSION")).strip
    git_sha, status = Open3.capture2("git", "rev-parse", "--short", "HEAD", chdir: Rails.root)
    abort("build_info:generate — `git rev-parse` failed") unless status.success?

    build_info = {
      "version" => version,
      "git_sha" => git_sha.strip,
      "build_date" => Time.now.utc.iso8601
    }

    File.write(Rails.root.join("config/build_info.yml"), build_info.to_yaml)
    puts "Wrote config/build_info.yml: #{build_info}"
  end
end
