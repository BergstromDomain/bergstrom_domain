# spec/support/authentication_helpers.rb

# ── Named test users ────────────────────────────────────────────────────────
# The following named users are used consistently across all feature specs.
# Gary Guest               — unauthenticated visitor, no account, no let declaration needed
# Uno User                 — create(:user)                      app_user role
# Ulrika User              — create(:user)                      app_user role
# Charlie Content Creator  — create(:user, :content_creator)    content_creator role
# Chris Content Creator    — create(:user, :content_creator)    content_creator role
# Curtis Content Creator   — create(:user, :content_creator)    content_creator role
# Adam Admin               — create(:user, :admin)              admin role
# Sam SysAdmin             — create(:user, :system_admin)       system_admin role
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
end
