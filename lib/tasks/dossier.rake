# lib/tasks/dossier.rake

namespace :dossier do
  namespace :skills do
    desc "Add the Soft Skills category and its Skills (renaming Professional Skills), leaving any already there"
    task soft: :environment do
      category = Dossier::SoftSkills.seed!
      puts "#{category.name}: #{category.skills.order(:name).pluck(:name).join(', ')}"
    end

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

  namespace :linkedin do
    desc "Scan LinkedIn export zips into a People manifest and a Colleague suggestions list: dossier:linkedin:scan[OUT,EMAIL,ZIP...]"
    task :scan, [ :out, :email ] => :environment do |_task, args|
      archives = args.extras.map { |path| File.expand_path(path) }
      user = User.find_by(email_address: args[:email].to_s.strip.downcase)
      abort "Usage: bin/rails 'dossier:linkedin:scan[OUT,EMAIL,ZIP,ZIP…]'" if args[:out].blank? || archives.empty?
      abort "No user with the email #{args[:email].inspect}." if user.nil?

      scan = Dossier::LinkedinScan.new(archives, user: user)
      suggestions = args[:out].sub(/(\.ya?ml)?\z/, "_colleague_suggestions.md")
      File.write(args[:out], scan.to_yaml)
      File.write(suggestions, scan.suggestions_markdown)
      puts "Wrote #{args[:out]} (#{scan.connections.size} connections) and #{suggestions}: review them, then run dossier:linkedin:apply."
    end

    desc "Add a reviewed LinkedIn manifest's connections to People: dossier:linkedin:apply[MANIFEST,EMAIL]; DRY_RUN=1 reports without saving"
    task :apply, [ :manifest, :email ] => :environment do |_task, args|
      user = User.find_by(email_address: args[:email].to_s.strip.downcase)
      abort "No user with the email #{args[:email].inspect}." if user.nil?
      abort "Usage: bin/rails 'dossier:linkedin:apply[MANIFEST,EMAIL]'" if args[:manifest].blank?

      dry_run = ENV["DRY_RUN"].present?
      report = Dossier::LinkedinImport.new(YAML.safe_load_file(args[:manifest]), user: user).apply!(dry_run: dry_run)
      puts report.empty? ? "Nothing to change." : report
      puts "#{report.count { |line| line.start_with?('Added') }} added, #{report.count { |line| line.start_with?('Updated') }} updated, " \
           "#{report.count { |line| line.start_with?('Skipped') }} skipped."
      puts "(dry run: nothing saved)" if dry_run
    rescue Dossier::LinkedinImport::Error => e
      abort "Nothing applied. #{e.message}"
    end
  end

  namespace :contributions do
    desc "Add the two All Things Testing Brisbane talks to a user, posters from POSTER_DIR: dossier:contributions:seed_talks[EMAIL,POSTER_DIR]"
    task :seed_talks, [ :email, :poster_dir ] => :environment do |_task, args|
      user = User.find_by(email_address: args[:email].to_s.strip.downcase)
      abort "Usage: bin/rails 'dossier:contributions:seed_talks[EMAIL,POSTER_DIR]'. No user with the email #{args[:email].inspect}." if user.nil?

      puts Dossier::SeedTalks.new(user, poster_dir: args[:poster_dir].presence).run!.notes
    end
  end
end
