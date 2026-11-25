# .claude/skills/new-app-scaffold/scripts/check_scaffold.rb
#
# Checks that a new app's Block 0 scaffold touches every place it has to.
# Plain Ruby (no Rails boot), run from the repo root:
#
#   ruby .claude/skills/new-app-scaffold/scripts/check_scaffold.rb --prefix Docket
#   ruby .claude/skills/new-app-scaffold/scripts/check_scaffold.rb --prefix Recipes --key recipes \
#        --brand Cookbook --route cookbook --icon chef-hat
#   ruby .claude/skills/new-app-scaffold/scripts/check_scaffold.rb --icons list-checks,clipboard-list
#
# --key defaults to the prefix downcased, --brand to the prefix, --route to the
# brand downcased. --icons checks Lucide icon names and exits: each is reported
# as MISSING (not in lucide-rails), FREE, or USED (with the file:line of every
# existing use under app/, so a new app icon doesn't clash with a button).
# Exits 1 if anything is missing, listing each miss with the file to fix.

require "optparse"

opts = {}
OptionParser.new do |o|
  o.on("--prefix NAME")  { |v| opts[:prefix] = v }
  o.on("--key NAME")     { |v| opts[:key] = v }
  o.on("--brand NAME")   { |v| opts[:brand] = v }
  o.on("--route NAME")   { |v| opts[:route] = v }
  o.on("--icon NAME")    { |v| opts[:icon] = v }
  o.on("--icons LIST")   { |v| opts[:icons] = v.split(",").map(&:strip) }
  o.on("--root DIR")     { |v| opts[:root] = v }
end.parse!

ROOT = File.expand_path(opts[:root] || Dir.pwd)

def lucide_icon_dir
  dirs = Dir.glob(File.expand_path("~/.rbenv/versions/*/lib/ruby/gems/*/gems/lucide-rails-*/icons/stripped"))
  begin
    spec = Gem::Specification.find_by_name("lucide-rails")
    dirs.unshift(File.join(spec.gem_dir, "icons", "stripped"))
  rescue Gem::MissingSpecError
    # Not on this Ruby's gem path; the rbenv glob above may still find it.
  end
  lock = File.read(File.join(ROOT, "Gemfile.lock")) rescue ""
  locked = lock[/^\s+lucide-rails \(([\d.]+)\)/, 1]
  dirs.find { |d| locked.nil? || d.include?("lucide-rails-#{locked}/") } || dirs.first
end

def check_icons(names)
  dir = lucide_icon_dir
  abort "Could not find the installed lucide-rails icons; run with `bundle exec ruby …`." unless dir && Dir.exist?(dir)
  names.map { |n| [ n, File.exist?(File.join(dir, "#{n}.svg")) ] }
end

# Every place under app/ that already renders this Lucide icon, as "path:line".
# Matches lucide_icon("name" and icon: "name" (helpers and seeds pass it that way).
def icon_uses(name)
  pattern = /(?:lucide_icon\(\s*|icon:\s*)["']#{Regexp.escape(name)}["']/
  Dir.glob(File.join(ROOT, "app", "**", "*.{erb,rb}")).sort.flat_map do |file|
    File.readlines(file).each_with_index.filter_map do |line, i|
      "#{file.delete_prefix("#{ROOT}/")}:#{i + 1}" if line.match?(pattern)
    end
  end
end

if opts[:icons]
  results = check_icons(opts[:icons])
  results.each do |name, ok|
    uses = ok ? icon_uses(name) : []
    status = !ok ? "MISSING" : uses.empty? ? "FREE   " : "USED   "
    puts "#{status} #{name}#{uses.empty? ? '' : "  (#{uses.size}x: #{uses.first(5).join(', ')}#{uses.size > 5 ? ', …' : ''})"}"
  end
  exit(results.all?(&:last) ? 0 : 1)
end

abort "Usage: --prefix NAME [--key --brand --route --icon] (or --icons a,b,c)" unless opts[:prefix]

prefix = opts[:prefix]
key    = opts[:key]   || prefix.downcase
brand  = opts[:brand] || prefix
route  = opts[:route] || brand.downcase

def read(path)
  full = File.join(ROOT, path)
  File.exist?(full) ? File.read(full) : nil
end

checks = []
check = ->(label, path, ok) { checks << [ label, path, ok ] }

apps_regex = /APPS="([^"]*)"/
%w[.githooks/commit-msg .githooks/pre-push .github/workflows/commit-lint.yml].each do |path|
  src = read(path).to_s
  check.call("commit prefix '#{prefix}' in APPS", path, src[apps_regex, 1].to_s.split("|").include?(prefix))
end
check.call("commit prefix in help text", ".githooks/commit-msg", read(".githooks/commit-msg").to_s.match?(/echo .*\b#{Regexp.escape(prefix)}\b/))
check.call("'# #{prefix}' line", ".gitmessage", read(".gitmessage").to_s.match?(/^#\s*#{Regexp.escape(prefix)}\s*$/))

enum_line = /^\s*#{Regexp.escape(key)}:\s*"#{Regexp.escape(key)}"/
check.call("enum :app_name #{key}", "app/models/app_permission.rb", read("app/models/app_permission.rb").to_s.match?(enum_line))
uas = read("app/models/user_app_setting.rb").to_s
check.call("enum :app_name #{key}", "app/models/user_app_setting.rb", uas.match?(enum_line))
check.call("DISPLAY_NAMES #{key} => #{brand}", "app/models/user_app_setting.rb", uas.match?(/"#{Regexp.escape(key)}"\s*=>\s*"#{Regexp.escape(brand)}"/))
gp = read("app/models/guide_page.rb").to_s
check.call("enum :app_section #{key}", "app/models/guide_page.rb", gp.match?(enum_line))
check.call("APP_SECTION_LABELS #{key} => #{brand}", "app/models/guide_page.rb", gp.match?(/"#{Regexp.escape(key)}"\s*=>\s*"#{Regexp.escape(brand)}"/))
check.call("app_name_for :#{key}", "app/models/policy.rb", read("app/models/policy.rb").to_s.match?(/when\b.*:#{Regexp.escape(key)}\b.*then "#{Regexp.escape(key)}"/))

check.call("get \"#{route}\" => pages##{route}", "config/routes.rb", read("config/routes.rb").to_s.match?(/get\s+"#{Regexp.escape(route)}",\s*to:\s*"pages##{Regexp.escape(route)}"/))
pc = read("app/controllers/pages_controller.rb").to_s
check.call("def #{route}", "app/controllers/pages_controller.rb", pc.match?(/def #{Regexp.escape(route)}\b/))
check.call("#{route} keeps the left nav (skip_before_action except:)", "app/controllers/pages_controller.rb", pc[/skip_before_action :set_left_nav, except: %i\[([^\]]*)\]/, 1].to_s.split.include?(route))
check.call("#{route} public (allow_unauthenticated_access) — skip if deliberately private", "app/controllers/pages_controller.rb", pc[/allow_unauthenticated_access only: %i\[([^\]]*)\]/, 1].to_s.split.include?(route))
check.call("Navigable returns :#{key} for pages##{route}", "app/controllers/concerns/navigable.rb", read("app/controllers/concerns/navigable.rb").to_s.match?(/return :#{Regexp.escape(key)}\s+if controller == "pages" && action == "#{Regexp.escape(route)}"/))

top = read("app/views/layouts/_top_nav.html.erb").to_s
apps_block = top[/label: "Apps".*?items:(.*?)\]/m, 1].to_s
labels = apps_block.scan(/label:\s*"([^"]+)"/).flatten
check.call("Apps menu has #{brand} -> #{route}_path", "app/views/layouts/_top_nav.html.erb", apps_block.match?(/label:\s*"#{Regexp.escape(brand)}",\s*path:\s*#{Regexp.escape(route)}_path/))
check.call("Apps menu alphabetical (#{labels.join(', ')})", "app/views/layouts/_top_nav.html.erb", !labels.empty? && labels == labels.sort_by(&:downcase))
left = read("app/views/layouts/_left_nav.html.erb").to_s
check.call("left nav branch :#{key}", "app/views/layouts/_left_nav.html.erb", left.match?(/@left_nav_section == :#{Regexp.escape(key)}\b/))
check.call("left nav h3 testid left-nav-#{route}-h3", "app/views/layouts/_left_nav.html.erb", left.include?("left-nav-#{route}-h3"))
check.call("left nav How To lists guide_pages_for_section(:#{key})", "app/views/layouts/_left_nav.html.erb", left.include?("guide_pages_for_section(:#{key})"))

view = read("app/views/pages/#{route}.html.erb")
check.call("landing view exists", "app/views/pages/#{route}.html.erb", !view.nil?)
check.call("landing view uses shared/app_landing with #{route}-hero.png", "app/views/pages/#{route}.html.erb", view.to_s.include?("shared/app_landing") && view.to_s.include?("#{route}-hero.png"))
check.call("no <%# path %> comment on line 1", "app/views/pages/#{route}.html.erb", !view.nil? && !view.lines.first.to_s.start_with?("<%#"))
check.call("hero image exists", "app/assets/images/#{route}-hero.png", File.exist?(File.join(ROOT, "app/assets/images/#{route}-hero.png")))

check.call("landing page feature spec", "spec/features/pages/#{route}_spec.rb", File.exist?(File.join(ROOT, "spec/features/pages/#{route}_spec.rb")))
check.call("Top Nav spec mentions #{brand}", "spec/features/layouts/top_nav_spec.rb", read("spec/features/layouts/top_nav_spec.rb").to_s.include?(brand))
check.call("Policy spec covers :#{key}", "spec/models/policy_spec.rb", read("spec/models/policy_spec.rb").to_s.include?(":#{key}"))
check.call("left nav request spec covers #{route}_path", "spec/requests/left_nav_spec.rb", read("spec/requests/left_nav_spec.rb").to_s.include?("#{route}_path"))
check.call("CLAUDE.md lists commit prefix", "CLAUDE.md", read("CLAUDE.md").to_s.match?(/`#{Regexp.escape(prefix)}`/))

if opts[:icon]
  ok = check_icons([ opts[:icon] ]).first.last
  check.call("Lucide icon '#{opts[:icon]}' exists", "lucide-rails", ok)
  check.call("left nav uses icon '#{opts[:icon]}'", "app/views/layouts/_left_nav.html.erb", left.include?("lucide_icon(\"#{opts[:icon]}\""))
end

notes = []
if opts[:icon]
  # Uses outside this app's own left nav branch and landing page.
  lines = left.lines
  start = lines.index { |l| l.match?(/@left_nav_section == :#{Regexp.escape(key)}\b/) }
  stop  = start && (lines[(start + 1)..].index { |l| l.include?("@left_nav_section ==") }&.+(start + 1) || lines.size)
  own = start ? ((start + 1)..stop).map { |n| "app/views/layouts/_left_nav.html.erb:#{n}" } : []
  others = icon_uses(opts[:icon]).reject { |u| own.include?(u) || u.start_with?("app/views/pages/#{route}.") }
  notes << "icon '#{opts[:icon]}' is also used at #{others.join(', ')}: tell the user (not a failure)" if others.any?
end

puts "Block 0 scaffold check — prefix #{prefix}, key #{key}, brand #{brand}, route #{route}"
checks.each { |label, path, ok| puts "#{ok ? '  ok  ' : '  MISS'}  #{label}  (#{path})" }
notes.each { |n| puts "  note  #{n}" }
missing = checks.reject(&:last)
puts
puts missing.empty? ? "All #{checks.size} checks pass." : "#{missing.size} of #{checks.size} checks missing."
exit(missing.empty? ? 0 : 1)
