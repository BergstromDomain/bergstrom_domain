# spec/services/build_info_service_spec.rb
require "rails_helper"

RSpec.describe BuildInfoService do
  around do |example|
    Dir.mktmpdir do |dir|
      @build_info_path = Pathname.new(dir).join("build_info.yml")
      @version_path    = Pathname.new(dir).join("VERSION")
      example.run
    end
  end

  def service
    described_class.new(build_info_path: @build_info_path, version_path: @version_path)
  end

  def stub_git(stdout: "", success: true)
    status = instance_double(Process::Status, success?: success)
    allow(Open3).to receive(:capture2).and_return([ stdout, status ])
  end

  context "Happy path" do
    it "Reads version, git_sha, and build_date from a generated build-info file" do
      @build_info_path.write({ "version" => "1.2.3", "git_sha" => "abc1234", "build_date" => "2026-01-01" }.to_yaml)

      expect(service.version).to eq("1.2.3")
      expect(service.git_sha).to eq("abc1234")
      expect(service.build_date).to eq("2026-01-01")
    end
  end

  context "Negative path" do
    it "Falls back to the VERSION file for version when no build-info file exists" do
      @version_path.write("9.9.9\n")

      expect(service.version).to eq("9.9.9")
    end

    it "Returns nil for version when neither the build-info file nor VERSION exist" do
      expect(service.version).to be_nil
    end

    it "Returns nil for git_sha when the git command fails" do
      stub_git(success: false)

      expect(service.git_sha).to be_nil
    end
  end

  context "Alternative path" do
    it "Falls back to file-based values when the build-info file is malformed YAML" do
      @build_info_path.write("not: valid: yaml: [")
      @version_path.write("4.5.6\n")

      expect(service.version).to eq("4.5.6")
    end

    it "Falls back per-field when the build-info file is missing individual keys" do
      @build_info_path.write({ "version" => "1.0.0" }.to_yaml)
      stub_git(stdout: "abc9999\n")

      expect(service.version).to eq("1.0.0")
      expect(service.git_sha).to eq("abc9999")
    end

    it "Falls back to the local git commit date for build_date when no build-info file exists" do
      stub_git(stdout: "2026-03-04\n")

      expect(service.build_date).to eq("2026-03-04")
    end
  end

  context "Edge cases" do
    it "Returns nil for git_sha when git is not installed" do
      allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)

      expect(service.git_sha).to be_nil
    end

    it "Returns nil for build_date when the git command fails and no build-info file exists" do
      stub_git(success: false)

      expect(service.build_date).to be_nil
    end
  end
end
