# spec/support/failure_artifacts.rb

# On a failing js: true example, saves a screenshot, the page HTML and the
# browser console log to tmp/screenshots — the folder CI's "Keep screenshots
# from failed system tests" step uploads as an artifact. Without this, that
# artifact was always empty and CI-only JS failures could only be guessed at.
RSpec.configure do |config|
  config.after(:each, js: true) do |example|
    next unless example.exception

    dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(dir)
    base = dir.join(example.full_description.parameterize.first(100)).to_s

    begin
      page.save_screenshot("#{base}.png")
      File.write("#{base}.html", page.html)
      logs = page.driver.browser.logs.get(:browser).map { |entry| "#{entry.level} #{entry.message}" }
      File.write("#{base}.log", ([ "path: #{page.current_path}" ] + logs).join("\n"))
    rescue StandardError => e
      warn "failure_artifacts: could not save artifacts for #{example.full_description}: #{e.message}"
    end
  end
end
