# spec/features/shared/confirm_dialog_spec.rb
require "rails_helper"

RSpec.describe "Confirm Dialog", type: :feature do
  let!(:user)   { create(:user, :content_creator) }
  let!(:person) { create(:person, :james_hetfield, user: user) }

  # See spec/features/blog_posts/comment_blog_post_spec.rb for provenance of
  # this retry wrapper — sign-in under the JS driver is occasionally flaky.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 3)
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
    find("[data-testid='confirm-dialog'][open]", visible: :all)
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
      find("[data-testid='confirm-dialog'][open]", visible: :all).click(x: -300, y: 0)

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
  end
end
