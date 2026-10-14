# spec/support/evidence.rb

# Evidence storyboards for manual testing: with EVIDENCE=1, a js: true example
# tagged evidence: "<app>/<feature>" saves a screenshot of the window after
# every step, with a caption, plus an index.html to page through:
#
#   EVIDENCE=1 bundle exec rspec spec/features/recipes/create_recipe_spec.rb
#   → docs/test-results/cookbook/evidence/write_a_recipe/index.html
#
# The folder is git-ignored — storyboards are for reviewing a feature before
# testing it by hand, not for keeping. Steps are Capybara's own actions (visit,
# click_on, fill_in, select, …), clicks on found elements, js_click, and
# anything a spec names itself with evidence_step("…") — e.g. a field it sets
# with execute_script, which Capybara never sees.
module Evidence
  Step = Data.define(:file, :caption)

  ACTIONS = %i[visit click_on click_link_or_button click_link click_button fill_in select choose check uncheck
               attach_file].freeze

  class << self
    attr_writer :root
    attr_reader :current

    def root
      @root || Rails.root.join("docs/test-results")
    end

    def enabled?
      ENV["EVIDENCE"].present?
    end

    def recording(recorder)
      @current = recorder
      @depth = 0
      yield
    ensure
      @current = nil
    end

    # Runs the action, then records one step. An action that runs another
    # inside it (click_button finds the button and clicks it) is still one
    # step, captioned by the outer one. The caption can be a lambda, so a
    # normal run never asks the browser for an element's details. An element,
    # if given, is scrolled into view for the screenshot.
    def step(caption, element = nil)
      return yield unless current

      outermost = @depth.zero?
      caption = caption.call if outermost && caption.respond_to?(:call)
      @depth += 1
      begin
        result = yield
      rescue StandardError
        @depth -= 1
        current.record("#{caption} (failed)", element) if outermost
        raise
      end
      @depth -= 1
      current.record(caption, element) if outermost
      result
    end

    def caption(action, args, options)
      locator = args.first
      case action
      when :visit then "Visit #{locator}"
      when :fill_in then "Fill in #{quote(locator || options[:id] || options[:name] || 'a field')} with #{quote(options[:with])}"
      when :select then [ "Select #{quote(locator)}", (" from #{quote(options[:from])}" if options[:from]) ].join
      when :choose, :check, :uncheck then "#{action.to_s.capitalize} #{quote(locator)}"
      when :attach_file then "Attach #{quote(Array(args[1]).map { |file| File.basename(file.to_s) }.join(', '))} to #{quote(locator)}"
      else "Click #{quote(locator)}"
      end
    end

    # What a person would call the element: a field's label (visible or
    # screen-reader only) or aria-label, else its text, else its testid.
    def describe(element)
      name = element.evaluate_script("this.labels?.[0]?.textContent || this.getAttribute('aria-label') || this.innerText || ''").squish
      return quote(name) if name.present?

      testid = element[:"data-testid"]
      testid.present? ? "[#{testid}]" : element.tag_name
    end

    def quote(value)
      %("#{value.to_s.truncate(40)}")
    end

    def write_feature_index(directory)
      examples = directory.glob("*/summary.json").map { |file| JSON.parse(file.read).merge("folder" => file.dirname.basename.to_s) }
      directory.join("index.html").write(Page.feature(directory, examples.sort_by { |example| example["title"] }))
    end
  end

  class Recorder
    attr_reader :steps, :directory

    def initialize(tag, title)
      app, feature = tag.to_s.split("/", 2)
      if feature.blank? || feature.include?("/")
        raise ArgumentError, "Tag evidence with the app and feature, e.g. \"cookbook/write_a_recipe\" — got #{tag.inspect}"
      end

      @title = title
      @feature_directory = Evidence.root.join(app, "evidence", feature)
      @directory = @feature_directory.join(title.parameterize.first(100))
      FileUtils.rm_rf(@directory)
      @directory.mkpath
      @steps = []
    end

    def record(caption, element = nil)
      element&.execute_script("this.scrollIntoView({ block: 'center', behavior: 'instant' })")
      settle
      file = format("%03d.png", @steps.size + 1)
      ScreenCapture.capture_window(@directory.join(file), session: Capybara.current_session)
      @steps << Step.new(file:, caption:)
    rescue StandardError => e
      @steps << Step.new(file: nil, caption: "#{caption} (no screenshot: #{e.message.lines.first&.strip})")
    end

    def finish(error)
      summary = { "title" => @title, "result" => error ? "Failed" : "Passed",
                  "error" => error&.message&.lines&.first(5)&.join, "recorded_at" => Time.now.strftime("%-d %b %Y %H:%M"),
                  "steps" => @steps.size }
      @directory.join("summary.json").write(JSON.pretty_generate(summary))
      @directory.join("index.html").write(Page.example(summary, @steps))
      Evidence.write_feature_index(@feature_directory)
    end

    private

    # Lets a click's page load or Turbo update finish before the screenshot.
    def settle
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
      sleep 0.15
      loop do
        ready = Capybara.current_session.evaluate_script(
          %(document.readyState === "complete" && !document.documentElement.hasAttribute("aria-busy"))
        )
        break if ready || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      rescue StandardError
        break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      ensure
        sleep 0.05 unless ready
      end
    end
  end

  # The storyboard pages: plain HTML with inline styles, opened from disk.
  module Page
    STYLE = <<~CSS.freeze
      body { font-family: system-ui, sans-serif; margin: 2rem; background: #f8f7f4; color: #1f1d1a; }
      h1 { font-size: 1.4rem; } .meta { color: #6b645c; }
      .passed { color: #2f7d32; font-weight: 600; } .failed { color: #b3261e; font-weight: 600; }
      pre { white-space: pre-wrap; background: #fff; border: 1px solid #e2ddd6; padding: 1rem; }
      .step { margin: 2rem 0; } .step h2 { font-size: 1rem; }
      .step img { max-width: 100%; border: 1px solid #e2ddd6; }
      table { border-collapse: collapse; background: #fff; } td, th { border: 1px solid #e2ddd6; padding: .5rem 1rem; text-align: left; }
    CSS

    module_function

    def example(summary, steps)
      h = ERB::Util.method(:html_escape)
      body = +"<h1>#{h.(summary['title'])}</h1>"
      body << %(<p class="meta"><span class="#{summary['result'].downcase}">#{summary['result']}</span> · #{summary['recorded_at']} · <a href="../index.html">All examples</a></p>)
      body << "<pre>#{h.(summary['error'])}</pre>" if summary["error"]
      steps.each_with_index do |step, index|
        body << %(<div class="step"><h2>#{index + 1}. #{h.(step.caption)}</h2>)
        body << %(<img src="#{step.file}" alt="#{h.(step.caption)}">) if step.file
        body << "</div>"
      end
      document(summary["title"], body)
    end

    def feature(directory, examples)
      h = ERB::Util.method(:html_escape)
      rows = examples.map do |example|
        %(<tr><td><a href="#{h.(example['folder'])}/index.html">#{h.(example['title'])}</a></td>) +
          %(<td class="#{example['result'].downcase}">#{example['result']}</td><td>#{example['steps']}</td><td>#{example['recorded_at']}</td></tr>)
      end
      title = directory.basename.to_s.humanize
      document(title, "<h1>#{h.(title)}</h1><table><tr><th>Example</th><th>Result</th><th>Steps</th><th>Recorded</th></tr>#{rows.join}</table>")
    end

    def document(title, body)
      <<~HTML
        <!doctype html>
        <html lang="en"><head><meta charset="utf-8"><title>#{ERB::Util.html_escape(title)}</title><style>#{STYLE}</style></head>
        <body>#{body}</body></html>
      HTML
    end
  end

  module SessionSteps
    ACTIONS.each do |action|
      define_method(action) do |*args, **options, &block|
        Evidence.step(-> { Evidence.caption(action, args, options) }) { super(*args, **options, &block) }
      end
    end
  end

  module ElementSteps
    def click(*args, **options)
      Evidence.step(-> { "Click #{Evidence.describe(self)}" }) { super }
    end

    def set(value, **options)
      Evidence.step(-> { "Fill in #{Evidence.describe(self)} with #{Evidence.quote(value)}" }) { super }
    end

    def select_option(*args, **options)
      Evidence.step(-> { "Select #{Evidence.quote(text.squish)}" }) { super }
    end
  end

  module Helpers
    # Names a step Capybara can't see, e.g. a field set with execute_script;
    # pass the element to have it scrolled into view for the screenshot.
    def evidence_step(caption, element = nil)
      Evidence.step(caption, element) { nil }
    end
  end
end

Capybara::Session.prepend(Evidence::SessionSteps)
Capybara::Node::Element.prepend(Evidence::ElementSteps)

RSpec.configure do |config|
  config.include Evidence::Helpers, type: :feature

  # Only js: true examples have a window to capture; the driver is switched
  # in a before hook, so the session is looked up when each step is recorded.
  config.around(:each, :evidence) do |example|
    next example.run unless Evidence.enabled? && example.metadata[:js]

    recorder = Evidence::Recorder.new(example.metadata[:evidence], example.full_description)
    Evidence.recording(recorder) { example.run }
    recorder.finish(example.exception)
  end
end
