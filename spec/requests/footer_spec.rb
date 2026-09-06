# spec/requests/footer_spec.rb
require "rails_helper"

RSpec.describe "Footer", type: :request do
  it "renders on a public page without authentication, with a real version and environment row" do
    get events_path

    expect(response.body).to include('data-testid="footer"')
    expect(response.body).to match(/v\d+\.\d+\.\d+/)
    expect(response.body).to include("Deployed Date:")
    expect(response.body).to include("Environment:")
    expect(response.body).to include("TEST")
  end
end
