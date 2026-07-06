require "rails_helper"

RSpec.describe "System Admin Users — Request Protection", type: :request do
  let!(:active_user)  { create(:user, status: "active") }
  let!(:pending_user) { create(:user, status: "pending") }

  it "Redirects a non-system-admin POST to approve" do
    post approve_system_admin_user_path(pending_user)
    expect(response).to redirect_to(new_session_path)
  end
end
