# spec/features/shared/confirm_dialog_spec.rb
require "rails_helper"

RSpec.describe "Confirm Dialog", type: :feature do
  let!(:user)   { create(:user, :content_creator) }
  let!(:person) { create(:person, :james_hetfield, user: user) }

  # See spec/features/blog_posts/comment_blog_post_spec.rb for provenance of
  # this retry wrapper — sign-in under the JS driver is occasionally flaky.
  # The sign-in form itself is a hard-navigation form (`data: { turbo: false }`
  # in app/views/sessions/new.html.erb), so each sign-in is a genuine full
  # page reload rather than a Turbo fetch — under load that occasionally
  # takes longer than a few seconds, hence the generous wait here.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 8)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end

  # Selenium's WebElement#displayed? doesn't reliably recognise a native
  # <dialog> shown via showModal() (a ChromeDriver top-layer quirk — the
  # `open` attribute is genuinely set in the DOM well before `displayed?`
  # agrees). Assert on the `open` attribute itself via `visible: :all`
  # instead of Capybara's default visible-element check.
  def open_delete_dialog_for(record)
    visit person_path(record)
    find("[data-testid='delete-button']").click
    find("[data-testid='confirm-dialog'][open]", visible: :all, wait: 5)
  end

  before { sign_in_and_settle(user) }

  # 1) Happy path ─────────────────────────────────────────────────────────────
  describe "Happy path" do
    it "shows the styled dialog with the trigger's message and proceeds with the action on Confirm", js: true do
      dialog = open_delete_dialog_for(person)
      expect(dialog).to have_text("Delete James Alan Hetfield? This cannot be undone.")

      find("[data-testid='confirm-dialog-confirm']").click

      expect(page).to have_current_path(people_path)
      expect(page).to have_css("[data-testid='flash-success']", text: "James Alan Hetfield has been successfully deleted")
      expect(Person.exists?(person.id)).to be false
    end
  end

  # 2) Negative path ──────────────────────────────────────────────────────────
  describe "Negative path" do
    it "does not perform the action and closes the dialog when Cancel is clicked", js: true do
      open_delete_dialog_for(person)

      find("[data-testid='confirm-dialog-cancel']").click

      expect(page).to have_no_css("[data-testid='confirm-dialog'][open]", visible: :all)
      expect(page).to have_current_path(person_path(person))
      expect(Person.exists?(person.id)).to be true
    end
  end

  # 3) Alternative path ───────────────────────────────────────────────────────
  describe "Alternative path" do
    it "cancels the action when Escape is pressed", js: true do
      open_delete_dialog_for(person)

      page.driver.browser.action.send_keys(:escape).perform

      expect(page).to have_no_css("[data-testid='confirm-dialog'][open]", visible: :all)
      expect(Person.exists?(person.id)).to be true
    end

    it "cancels the action when the dimmed backdrop is clicked", js: true do
      open_delete_dialog_for(person)

      # Selenium's click(x:, y:) offsets are relative to the element's
      # center (W3C WebDriver), not its top-left corner. The dialog fills
      # the viewport, so an offset well outside the centered card's
      # half-width lands on the backdrop.
      find("[data-testid='confirm-dialog'][open]", visible: :all, wait: 5).click(x: -300, y: 0)

      expect(page).to have_no_css("[data-testid='confirm-dialog'][open]", visible: :all)
      expect(Person.exists?(person.id)).to be true
    end
  end

  # 4) Edge cases ──────────────────────────────────────────────────────────────
  describe "Edge cases" do
    it "renders an HTML-unsafe message as plain text rather than markup", js: true do
      unsafe_person = create(:person, first_name: "Rob", last_name: "<b>O'Brien</b> & Sons", user: user)

      dialog = open_delete_dialog_for(unsafe_person)

      expect(dialog).to have_no_css("b")
      expect(dialog.text).to include("<b>O'Brien</b> & Sons")
    end

    it "returns focus to the triggering button after Cancel", js: true do
      open_delete_dialog_for(person)

      find("[data-testid='confirm-dialog-cancel']").click

      expect(page).to have_no_css("[data-testid='confirm-dialog'][open]", visible: :all)
      expect(page.evaluate_script("document.activeElement.dataset.testid")).to eq("delete-button")
    end

    it "keeps Tab focus trapped inside the dialog and lets Enter activate the focused button", js: true do
      open_delete_dialog_for(person)

      # Tab enough times to prove focus cycles within the dialog's two
      # buttons rather than escaping to the (inert) page behind it.
      4.times { page.driver.browser.action.send_keys(:tab).perform }
      focused_testid = page.evaluate_script("document.activeElement.dataset.testid")
      expect(%w[confirm-dialog-cancel confirm-dialog-confirm]).to include(focused_testid)

      page.evaluate_script("document.querySelector('[data-testid=\"confirm-dialog-confirm\"]').focus()")
      page.driver.browser.action.send_keys(:enter).perform

      expect(page).to have_current_path(people_path)
      expect(Person.exists?(person.id)).to be false
    end

    it "does not stack a second dialog when the trigger is clicked twice in rapid succession", js: true do
      open_delete_dialog_for(person)

      # A genuine second click can't reach the trigger once showModal()
      # makes the rest of the page inert — verify that directly (the
      # click either raises because the target is obscured/inert, or is a
      # no-op) rather than only stress-testing the open() guard via a
      # synthetic same-tick double `.click()`, which doesn't correspond to
      # anything a real user/browser can produce.
      begin
        find("[data-testid='delete-button']", visible: :all).click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError, Capybara::ElementNotFound
        # expected: the trigger is inert/obscured behind the open modal
      end

      expect(page).to have_css("[data-testid='confirm-dialog'][open]", visible: :all, count: 1)

      find("[data-testid='confirm-dialog-confirm']").click

      expect(page).to have_current_path(people_path)
      expect(Person.exists?(person.id)).to be false
    end

    it "opens cleanly again after being cancelled, and Confirm on the retry proceeds", js: true do
      open_delete_dialog_for(person)
      find("[data-testid='confirm-dialog-cancel']").click
      expect(page).to have_no_css("[data-testid='confirm-dialog'][open]", visible: :all)

      find("[data-testid='delete-button']").click
      find("[data-testid='confirm-dialog'][open]", visible: :all, wait: 5)
      find("[data-testid='confirm-dialog-confirm']").click

      expect(page).to have_current_path(people_path)
      expect(Person.exists?(person.id)).to be false
    end
  end
end
