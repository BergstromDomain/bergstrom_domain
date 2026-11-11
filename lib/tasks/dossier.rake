# lib/tasks/dossier.rake

namespace :dossier do
  namespace :skills do
    desc "Apply the Skill taxonomy (default db/seeds/dossier/skill_taxonomy.yml); DRY_RUN=1 reports without saving"
    task :apply, [ :path ] => :environment do |_task, args|
      path = args[:path].presence || Rails.root.join("db/seeds/dossier/skill_taxonomy.yml")
      dry_run = ENV["DRY_RUN"].present?
      report = Dossier::SkillTaxonomy.new(YAML.safe_load_file(path)).apply!(dry_run: dry_run)
      puts report.empty? ? "Nothing to change." : report
      puts "(dry run: nothing saved)" if dry_run
    rescue Dossier::SkillTaxonomy::Error => e
      abort "Nothing applied. #{e.message}"
    end
  end

  namespace :courses do
    desc "Scan a folder of course material into a manifest to review: dossier:courses:scan[DIR,OUT]"
    task :scan, [ :dir, :out ] => :environment do |_task, args|
      abort "Usage: bin/rails 'dossier:courses:scan[DIR,OUT]'" if args[:dir].blank? || args[:out].blank?

      scan = Dossier::CourseScan.new(File.expand_path(args[:dir]))
      File.write(args[:out], scan.to_yaml)
      puts "Wrote #{args[:out]}: review it, then run dossier:courses:apply."
    end

    desc "Apply a course manifest and the course providers' descriptions to a user: dossier:courses:apply[MANIFEST,EMAIL]; DRY_RUN=1 reports without saving"
    task :apply, [ :manifest, :email ] => :environment do |_task, args|
      user = User.find_by(email_address: args[:email].to_s.strip.downcase)
      abort "No user with the email #{args[:email].inspect}." if user.nil?

      dry_run = ENV["DRY_RUN"].present?
      providers = YAML.safe_load_file(Rails.root.join("db/seeds/dossier/course_providers.yml"))
      manifest = args[:manifest].present? ? YAML.safe_load_file(args[:manifest]) : { "root" => Dir.pwd, "courses" => [] }
      report = Dossier::CourseImport.new(manifest, providers: providers, user: user).apply!(dry_run: dry_run)
      puts report.empty? ? "Nothing to change." : report
      puts "(dry run: nothing saved)" if dry_run
    rescue Dossier::CourseImport::Error => e
      abort "Nothing applied. #{e.message}"
    end
  end
end
