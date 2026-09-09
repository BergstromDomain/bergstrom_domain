# spec/requests/system_admin/users_spec.rb
require "rails_helper"

RSpec.describe "Users", type: :request do
  let!(:active_user)  { create(:user, status: "active") }
  let!(:pending_user) { create(:user, status: "pending") }

  # 2) Negative Path ────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Redirects a non-system-admin POST to approve" do
      post approve_system_admin_user_path(pending_user)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
