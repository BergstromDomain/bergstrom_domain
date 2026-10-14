# spec/features/shared/evidence_spec.rb
require "rails_helper"

RSpec.describe "Evidence", type: :feature, js: true do
  let(:root) { Pathname.new(Dir.mktmpdir) }
  let(:feature) { root.join("cookbook/evidence/sign_in") }

  before { Evidence.root = root }

  after do
    Evidence.root = nil
    FileUtils.remove_entry(root)
  end

  def record(title = "Signs in", tag: "cookbook/sign_in", &block)
    recorder = Evidence::Recorder.new(tag, title)
    Evidence.recording(recorder, &block)
    recorder
  end

  def sign_in_steps
    visit new_session_path
    fill_in "Email address", with: "charlie@example.com"
    click_button "Sign In"
  end

  def png_size(path)
    File.binread(path, 8, 16).unpack("N2")
  end

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "Saves a captioned screenshot of the window after each step" do
      recorder = record { sign_in_steps }
      recorder.finish(nil)

      expect(recorder.steps.map(&:caption)).to eq([
        "Visit #{new_session_path}",
        'Fill in "Email address" with "charlie@example.com"',
        'Click "Sign In"'
      ])
      expect(recorder.directory.children.map { |file| file.basename.to_s }.sort)
        .to eq(%w[001.png 002.png 003.png index.html summary.json])
      expect(png_size(recorder.directory.join("001.png")))
        .to eq(page.evaluate_script("[window.innerWidth, window.innerHeight]"))
    end

    it "Writes a storyboard page with the example, its result and every step" do
      recorder = record { sign_in_steps }
      recorder.finish(nil)

      html = recorder.directory.join("index.html").read
      expect(html).to include("Signs in", "Passed", "Fill in &quot;Email address&quot; with &quot;charlie@example.com&quot;")
      expect(html).to include('src="001.png"', 'src="002.png"', 'src="003.png"')
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "Rejects a tag that doesn't name an app and a feature" do
      expect { Evidence::Recorder.new("sign_in", "Signs in") }.to raise_error(ArgumentError, /app.*feature/)
    end

    it "Records nothing when no recording is running" do
      sign_in_steps
      evidence_step("A step outside any recording")

      expect(root.children).to be_empty
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "Marks a failed example and keeps the steps up to the failure" do
      recorder = record { visit new_session_path }
      recorder.finish(RuntimeError.new("expected to find the toast"))

      expect(recorder.directory.join("index.html").read).to include("Failed", "expected to find the toast")
      expect(recorder.steps.size).to eq(1)
    end

    it "Replaces an earlier recording of the same example" do
      record { sign_in_steps }.finish(nil)

      recorder = record { visit new_session_path }
      recorder.finish(nil)

      expect(recorder.directory.join("002.png")).not_to exist
    end

    it "Records the steps a spec adds itself, and click_button's own inner click only once" do
      recorder = record do
        visit new_session_path
        evidence_step("Set the Password field")
        click_button "Sign In"
      end

      expect(recorder.steps.map(&:caption))
        .to eq([ "Visit #{new_session_path}", "Set the Password field", 'Click "Sign In"' ])
    end

    it "Names a click on a found element, or a js_click, by what it says" do
      recorder = record do
        visit new_session_path
        js_click("forgot-password-link")
        visit new_session_path
        find("[data-testid='sign-in-button']").click
      end

      expect(recorder.steps.map(&:caption)).to eq([
        "Visit #{new_session_path}", 'Click "Forgot password?"',
        "Visit #{new_session_path}", 'Click "Sign In"'
      ])
    end

    it "Falls back to the testid for an element with no label or text" do
      recorder = record do
        visit new_session_path
        page.execute_script("document.querySelector('[data-testid=\"sign-in-button\"]').textContent = ''")
        find("[data-testid='sign-in-button']").click
      end

      expect(recorder.steps.last.caption).to eq("Click [sign-in-button]")
    end
  end

  # 4) Edge cases ─────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "Lists every recorded example of a feature, with its result, on the feature's page" do
      record("Signs in") { visit new_session_path }.finish(nil)
      record("Rejects a wrong password") { visit new_session_path }.finish(RuntimeError.new("boom"))

      html = feature.join("index.html").read
      expect(html).to include("Signs in", "Rejects a wrong password", "Passed", "Failed")
    end

    it "Shortens long values and escapes HTML in captions" do
      recorder = record do
        visit new_session_path
        fill_in "Email address", with: "<b>#{'x' * 100}</b>"
      end
      recorder.finish(nil)

      expect(recorder.steps.last.caption.length).to be < 100
      expect(recorder.directory.join("index.html").read).not_to include("<b>x")
    end

    it "Names a field by its label rather than its testid" do
      recorder = record do
        visit new_session_path
        find("[data-testid='email-field']").set("charlie@example.com")
      end

      expect(recorder.steps.last.caption).to eq('Fill in "Email address" with "charlie@example.com"')
    end

    it "Scrolls the element a spec names into view before the screenshot" do
      recorder = record do
        visit new_session_path
        page.execute_script(<<~JS)
          const spacer = document.createElement("div")
          spacer.style.height = "2000px"
          document.querySelector('[data-testid="sign-in-panel"]').before(spacer)
        JS
        evidence_step("Look at the sign-in panel", find("[data-testid='sign-in-panel']"))
      end

      expect(recorder.steps.last.caption).to eq("Look at the sign-in panel")
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const rect = document.querySelector('[data-testid="sign-in-panel"]').getBoundingClientRect()
          return rect.top >= 0 && rect.top < window.innerHeight
        })()
      JS
    end

    it "Keeps recordings out of git" do
      ignored = system("git", "check-ignore", "-q", "docs/test-results/cookbook/evidence/sign_in/signs-in/index.html",
        chdir: Rails.root.to_s)

      expect(ignored).to be(true)
    end
  end
end
