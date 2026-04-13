# spec/models/event_type_spec.rb (temporary — expanded in Phase 2)
require "rails_helper"

RSpec.describe EventType, type: :model do
  describe "LUCIDE_VALID_ICONS" do
    it "is a non-empty Set" do
      expect(EventType::LUCIDE_VALID_ICONS).to be_a(Set)
      expect(EventType::LUCIDE_VALID_ICONS).not_to be_empty
    end

    it "includes known Lucide icon names" do
      expect(EventType::LUCIDE_VALID_ICONS).to include("music", "cake", "trophy")
    end

    it "does not include made-up names" do
      expect(EventType::LUCIDE_VALID_ICONS).not_to include("not-a-real-icon", "icon-1")
    end
  end
end
