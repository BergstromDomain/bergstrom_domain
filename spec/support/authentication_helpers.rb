# spec/support/authentication_helpers.rb

# ── Named test users ────────────────────────────────────────────────────────
# The following named users are used consistently across all feature specs.
# Gary Guest               — unauthenticated visitor, no account, no let declaration needed
# Pat Pending              — create(:user)                      status: "pending"
# Sue Suspended            — create(:user)                      status: "suspended"   app_user role
# Uno User                 — create(:user)                      status: "active"      app_user role
# Ulrika User              — create(:user)                      status: "active"      app_user role
# Charlie Content Creator  — create(:user, :content_creator)    status: "active"      content_creator role
# Chris Content Creator    — create(:user, :content_creator)    status: "active"      content_creator role
# Curtis Content Creator   — create(:user, :content_creator)    status: "active"      content_creator role
# Adam Admin               — create(:user, :admin)              status: "active"      admin role
# Sam SysAdmin             — create(:user, :system_admin)       status: "active"      system_admin role
#
# All factory users default to status: :active and password: "password123".
# Gary Guest is the only visitor who is not signed in — just visit the path directly.
# ────────────────────────────────────────────────────────────────────────────

module AuthenticationHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password",      with: "password123"
    click_button "Sign In"
  end

  # For js: true specs: sign_in_as returns once the click is sent, so a visit
  # straight after can race the sign-in and land on the Sign In page. This waits
  # for the signed-in avatar, retrying if the click dispatched nothing. Some
  # older specs still define their own copy, which takes precedence.
  def sign_in_and_settle(user, attempts: 3)
    attempts.times do
      sign_in_as(user)
      return if page.has_css?("[data-testid='user-thumbnail-dropdown']", wait: 10)
    end
    raise "sign_in_and_settle: could not sign in as #{user.email_address} after #{attempts} attempts"
  end
end
