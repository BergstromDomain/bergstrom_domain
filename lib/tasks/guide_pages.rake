# lib/tasks/guide_pages.rake

namespace :guide_pages do
  desc "Create or update User Guide pages from docs/user-guide/<app>/*.md, e.g. guide_pages:load[cookbook]"
  task :load, [ :app ] => :environment do |_task, args|
    abort "Usage: bin/rails guide_pages:load[cookbook]" if args[:app].blank?

    result = GuidePageLoader.new(Rails.root.join("docs/user-guide", args[:app])).call
    result.each { |status, titles| puts "#{status.to_s.capitalize} (#{titles.size}): #{titles.join(', ')}" }
  rescue GuidePageLoader::Error => e
    abort "Nothing loaded. #{e.message}"
  end

  desc "Delete the User Guide pages listed in docs/user-guide/retired.yml"
  task retire: :environment do
    result = GuidePageRetirer.new(Rails.root.join("docs/user-guide")).call
    puts "Removed (#{result[:removed].size}): #{result[:removed].join(', ')}"
    puts "Already gone (#{result[:absent].size}): #{result[:absent].join(', ')}"
  rescue GuidePageRetirer::Error => e
    abort "Nothing retired. #{e.message}"
  end
end
