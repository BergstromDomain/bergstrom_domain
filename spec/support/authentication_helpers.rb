# spec/support/authentication_helpers.rb
module AuthenticationHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password",      with: "password123"
    click_button "Sign in"
  end
end
