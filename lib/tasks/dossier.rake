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
end
