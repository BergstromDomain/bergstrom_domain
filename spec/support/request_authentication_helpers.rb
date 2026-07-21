module RequestAuthenticationHelpers
  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end
end
