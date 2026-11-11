# spec/services/dossier/linkedin_import_spec.rb
require "rails_helper"

# Applies a reviewed LinkedIn manifest to People: each connection a Restricted
# Person of the user's, with their LinkedIn and position.
RSpec.describe Dossier::LinkedinImport do
  let(:charlie) { create(:user, :content_creator) }

  def connection(**overrides)
    { "name_on_linkedin" => "Anna Andersson", "first_name" => "Anna", "last_name" => "Andersson",
      "linkedin" => "https://www.linkedin.com/in/anna", "company" => "Telstra", "position" => "Test Lead",
      "connected_on" => "2026-10-05", "suggested" => [ { "assignment_id" => 1, "assignment" => "Test Lead at Telstra" } ] }
      .merge(overrides.transform_keys(&:to_s))
  end

  def import(connections, dry_run: false)
    described_class.new({ "connections" => connections }, user: charlie).apply!(dry_run: dry_run)
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Adds each connection as a Restricted Person with their LinkedIn and position, and no Colleague" do
      report = import([ connection ])

      anna = Person.sole
      expect(anna).to have_attributes(full_name: "Anna Andersson", user: charlie, classification: "restricted",
                                      description: "Test Lead at Telstra", work_email: nil,
                                      linkedin_url: "https://www.linkedin.com/in/anna")
      expect(Dossier::Colleague.count).to eq(0)
      expect(report).to eq([ "Added Anna Andersson" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Leaves another user's Person of the same name alone" do
      theirs = create(:person, first_name: "Anna", last_name: "Andersson", description: "")
      report = import([ connection ])

      expect(theirs.reload.description).to eq("")
      expect(theirs.linkedin_url).to be_nil
      expect(report).to eq([ "Skipped Anna Andersson: someone else's Person" ])
    end

    it "Skips a connection with no first name" do
      expect(import([ connection(first_name: " ", name_on_linkedin: "🚀") ])).to eq([ "Skipped 🚀: no first name" ])
      expect(Person.count).to eq(0)
    end

    it "Saves nothing when a connection can't be saved, naming it" do
      allow_any_instance_of(Person).to receive(:save).and_wrap_original do |original, *args|
        original.receiver.first_name == "Bad" ? (original.receiver.errors.add(:base, "Broken") && false) : original.call(*args)
      end

      expect { import([ connection, connection(first_name: "Bad", name_on_linkedin: "Bad Row") ]) }
        .to raise_error(described_class::Error, "Bad Row: Broken")
      expect(Person.count).to eq(0)
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Fills only the blanks of your own Person of the same name, in any case" do
      mine = create(:person, user: charlie, first_name: "anna", last_name: "ANDERSSON", description: "")
      report = import([ connection ])

      expect(mine.reload).to have_attributes(description: "Test Lead at Telstra", linkedin_url: "https://www.linkedin.com/in/anna")
      expect(report).to eq([ "Updated anna ANDERSSON: LinkedIn, description" ])
    end

    it "Reports the changes on a dry run and saves nothing" do
      expect(import([ connection ], dry_run: true)).to eq([ "Added Anna Andersson" ])
      expect(Person.count).to eq(0)
    end

    it "Changes nothing on a second run" do
      import([ connection ])

      expect(import([ connection ])).to be_empty
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Merges two connections of the same name into one Person" do
      report = import([ connection, connection(linkedin: "https://www.linkedin.com/in/anna-2") ])

      expect(Person.sole.linkedin_url).to eq("https://www.linkedin.com/in/anna")
      expect(report).to eq([ "Added Anna Andersson" ])
    end

    it "Adds a Person with no last name, company or LinkedIn" do
      import([ connection(last_name: nil, company: nil, position: nil, linkedin: nil) ])

      expect(Person.sole).to have_attributes(full_name: "Anna", description: nil, linkedin_url: nil)
    end

    it "Takes the company alone as the description" do
      import([ connection(position: nil) ])

      expect(Person.sole.description).to eq("Telstra")
    end
  end
end
