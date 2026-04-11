require "rails_helper"

RSpec.describe EventPerson, type: :model do
  describe "database columns" do
    it { is_expected.to have_db_column(:event_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:person_id).of_type(:integer).with_options(null: false) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:person) }
  end
end
