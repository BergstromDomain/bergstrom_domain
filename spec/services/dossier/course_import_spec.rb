# spec/services/dossier/course_import_spec.rb
require "rails_helper"

# Applies a course manifest (from Dossier::CourseScan, after review) and the
# course providers' descriptions to one user's Credentials.
RSpec.describe Dossier::CourseImport do
  let(:charlie) { create(:user, :content_creator) }
  let(:root) { Pathname(Dir.mktmpdir) }
  let!(:course_type) { create(:dossier_credential_type, :training, name: "Course", position: 4) }

  after { FileUtils.remove_entry(root) }

  def certificate(relative)
    path = root.join(relative)
    path.dirname.mkpath
    FileUtils.cp(file_fixture("test_certificate.pdf"), path)
    relative
  end

  def entry(**overrides)
    { "title" => "Learning Docker", "provider" => "LinkedIn Learning", "folder" => "LinkedIn Learning/DevOps/Learning_Docker",
      "status" => "completed", "started" => "2022-11-03", "completed" => "2022-11-03", "precision" => "day",
      "certificate_number" => "AZ-1", "verification_url" => nil, "skills" => [ "Docker" ], "certificates" => [] }
      .merge(overrides.transform_keys(&:to_s))
  end

  def import(courses, providers: [], dry_run: false)
    described_class.new({ "root" => root.to_s, "courses" => courses }, providers: providers, user: charlie).apply!(dry_run: dry_run)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Creates a Course with its provider, dates, status, Skills and certificate" do
      path = certificate("LinkedIn Learning/DevOps/Learning_Docker/Certificates/Docker.pdf")
      report = import([ entry(certificates: [ path ]) ])

      course = charlie.dossier_credentials.find_by!(title: "Learning Docker")
      expect(course).to have_attributes(credential_type: course_type, status: "completed", start_on: Date.new(2022, 11, 3),
                                        end_on: Date.new(2022, 11, 3), end_precision: "day", certificate_number: "AZ-1",
                                        skills_text: "Docker")
      expect(course.provider.name).to eq("LinkedIn Learning")
      expect(course.files.map { |file| file.filename.to_s }).to eq([ "Docker.pdf" ])
      expect(report).to include("Added Learning Docker (Completed, 1 certificate)")
    end

    it "Fills in the course providers' descriptions, creating missing providers" do
      create(:dossier_organisation, name: "LinkedIn Learning")
      report = import([], providers: [ { "name" => "LinkedIn Learning", "description" => "Video courses." },
                                       { "name" => "Udemy", "description" => "A course marketplace." } ])

      expect(Dossier::Organisation.find_by!(name: "LinkedIn Learning").description).to eq("Video courses.")
      expect(Dossier::Organisation.find_by!(name: "Udemy").description).to eq("A course marketplace.")
      expect(report).to include("Described LinkedIn Learning", "Added provider Udemy")
    end

    it "Adds an In Progress course with no certificate" do
      import([ entry(status: "in_progress", completed: nil, precision: "month", started: "2021-06-01", certificate_number: nil) ])

      expect(charlie.dossier_credentials.find_by!(title: "Learning Docker"))
        .to have_attributes(status: "in_progress", end_on: nil, start_on: Date.new(2021, 6, 1), start_precision: "month")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Saves nothing when an entry is invalid, naming it" do
      expect { import([ entry(title: "Fine"), entry(title: "", folder: "Udemy/Broken") ]) }
        .to raise_error(described_class::Error, /Udemy\/Broken: Title can't be blank/)
      expect(Dossier::Credential.count).to eq(0)
    end

    it "Reports a certificate file that isn't there and adds the course without it" do
      report = import([ entry(certificates: [ "LinkedIn Learning/missing.pdf" ]) ])

      expect(report).to include("Missing certificate LinkedIn Learning/missing.pdf")
      expect(charlie.dossier_credentials.find_by!(title: "Learning Docker").files).not_to be_attached
    end

    it "Needs a Course Credential Type" do
      course_type.destroy!

      expect { import([ entry ]) }.to raise_error(described_class::Error, /Course Credential Type/)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Reports the changes on a dry run and saves nothing" do
      report = import([ entry ], providers: [ { "name" => "Udemy", "description" => "A course marketplace." } ], dry_run: true)

      expect(report).to include("Added Learning Docker (Completed, 0 certificates)", "Added provider Udemy")
      expect(Dossier::Credential.count).to eq(0)
      expect(Dossier::Organisation.find_by(name: "Udemy")).to be_nil
    end

    it "Matches an existing Credential by title in any case, filling only its blanks" do
      existing = create(:dossier_credential, user: charlie, credential_type: course_type, title: "learning docker",
                                             certificate_number: nil, description: "Mine.", start_on: Date.new(2020, 1, 1),
                                             end_on: Date.new(2020, 1, 1))
      path = certificate("LinkedIn Learning/DevOps/Learning_Docker/Certificates/Docker.pdf")
      report = import([ entry(certificates: [ path ]) ])

      expect(existing.reload).to have_attributes(certificate_number: "AZ-1", description: "Mine.", start_on: Date.new(2020, 1, 1))
      expect(existing.provider.name).to eq("LinkedIn Learning")
      expect(existing.files).to be_attached
      expect(report).to include("Updated learning docker: provider, certificate number, Skills, certificate")
    end

    it "Changes nothing on a second run" do
      import([ entry ], providers: [ { "name" => "Udemy", "description" => "A course marketplace." } ])

      expect(import([ entry ], providers: [ { "name" => "Udemy", "description" => "A course marketplace." } ])).to be_empty
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Keeps a provider's description someone already wrote" do
      create(:dossier_organisation, name: "Udemy", description: "Written by hand.")
      import([], providers: [ { "name" => "Udemy", "description" => "A course marketplace." } ])

      expect(Dossier::Organisation.find_by!(name: "Udemy").description).to eq("Written by hand.")
    end

    it "Adds a course with no provider" do
      import([ entry(provider: nil) ])

      expect(charlie.dossier_credentials.find_by!(title: "Learning Docker").provider).to be_nil
    end

    it "Has a name and a one- or two-sentence description for every provider in the committed seed" do
      providers = YAML.safe_load_file(Rails.root.join("db/seeds/dossier/course_providers.yml"))

      expect(providers.map { |row| row.keys.sort }.uniq).to eq([ %w[description name] ])
      expect(providers.map { |row| row["name"].downcase }).to eq(providers.map { |row| row["name"].downcase }.uniq)
      expect(providers.map { |row| row["description"].length }).to all(be_between(40, 240))
    end

    it "Ignores another user's Credential of the same title" do
      create(:dossier_credential, credential_type: course_type, title: "Learning Docker")
      import([ entry ])

      expect(charlie.dossier_credentials.where(title: "Learning Docker").count).to eq(1)
    end
  end
end
