# spec/services/dossier/linkedin_scan_spec.rb
require "rails_helper"

# Reads a LinkedIn export's connections into a manifest to review, suggesting
# the Assignments each may have worked on with you.
RSpec.describe Dossier::LinkedinScan do
  let(:charlie) { create(:user, :content_creator) }
  let(:plotlogic) { create(:dossier_organisation, name: "Plotlogic") }
  let(:engagement) do
    create(:dossier_engagement, user: charlie, employer: plotlogic, start_on: Date.new(2023, 2, 1), end_on: Date.new(2024, 8, 1))
  end
  let!(:assignment) do
    create(:dossier_assignment, engagement: engagement, client: plotlogic,
                                role: create(:dossier_role, name: "Test Lead"),
                                start_on: Date.new(2023, 2, 1), end_on: Date.new(2024, 8, 1))
  end

  def csv(*rows)
    <<~CSV
      Notes:
      "When exporting your connection data, you may notice that some of the email addresses are missing."

      First Name,Last Name,URL,Email Address,Company,Position,Connected On
      #{rows.join("\n")}
    CSV
  end

  def scan(text, archives: [ "export.zip" ])
    described_class.new(archives, user: charlie, today: Date.new(2026, 11, 11), read: ->(_archive, _member) { text })
  end

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Reads each connection's name, profile, company, position and the day you connected" do
      entry = scan(csv("Anna,Andersson,https://www.linkedin.com/in/anna,,Telstra,Test Lead,05 Oct 2026")).connections.sole

      expect(entry).to eq("name_on_linkedin" => "Anna Andersson", "first_name" => "Anna", "last_name" => "Andersson",
                          "linkedin" => "https://www.linkedin.com/in/anna", "company" => "Telstra",
                          "position" => "Test Lead", "connected_on" => "2026-10-05", "suggested" => [])
    end

    it "Suggests an Assignment at their company that ran when you connected" do
      entry = scan(csv("Bo,Berg,https://www.linkedin.com/in/bo,,Plotlogic Pty Ltd,Developer,10 Jan 2024")).connections.sole

      expect(entry["suggested"]).to eq([ { "assignment_id" => assignment.id,
                                           "assignment" => "Test Lead at Plotlogic (Plotlogic, Feb 2023 – Aug 2024)" } ])
    end

    it "Lists the suggestions by Assignment as Markdown" do
      markdown = scan(csv("Bo,Berg,https://www.linkedin.com/in/bo,,Plotlogic,Developer,10 Jan 2024")).suggestions_markdown

      expect(markdown).to include("1 suggestions", "## Test Lead at Plotlogic (Plotlogic, Feb 2023 – Aug 2024)",
                                  "| [Bo Berg](https://www.linkedin.com/in/bo) | Plotlogic | Developer | 2024-01-10 |")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Doesn't suggest an Assignment you'd left more than three months before connecting, or another company's" do
      text = csv("Bo,Berg,https://www.linkedin.com/in/bo,,Plotlogic,Developer,10 Dec 2024",
                 "Cy,Cole,https://www.linkedin.com/in/cy,,Telstra,Developer,10 Jan 2024")

      expect(scan(text).connections.map { |entry| entry["suggested"] }).to eq([ [], [] ])
    end

    it "Has no connections without a Connections.csv" do
      expect(scan(nil).connections).to eq([])
    end

    it "Leaves out hidden members, who have no name" do
      expect(scan(csv(",,,,,,05 Oct 2026")).connections).to eq([])
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Suggests an Assignment by its Vendor, connected within three months of its end" do
      create(:dossier_assignment_partner, assignment: assignment, organisation: create(:dossier_organisation, name: "PwC"))
      entry = scan(csv("Bo,Berg,https://www.linkedin.com/in/bo,,PwC Australia,Manager,30 Oct 2024")).connections.sole

      expect(entry["suggested"].map { |suggestion| suggestion["assignment_id"] }).to eq([ assignment.id ])
    end

    it "Reads the first export that has the connections" do
      reads = { "basic.zip" => nil, "complete.zip" => csv("Anna,Andersson,https://www.linkedin.com/in/anna,,,,05 Oct 2026") }
      scan = described_class.new(reads.keys, user: charlie, read: ->(archive, _member) { reads[archive] })

      expect(scan.connections.map { |entry| entry["first_name"] }).to eq([ "Anna" ])
      expect(YAML.safe_load(scan.to_yaml)).to include("source" => [ "basic.zip", "complete.zip" ])
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Cleans emoji, nicknames, pronouns and credentials out of names" do
      {
        [ "Elizabeth (Liz)", "Kirk (PhD)" ] => [ "Elizabeth", "Kirk" ],
        [ "🚀  Sam", "McNamara" ] => [ "Sam", "McNamara" ],
        [ "Nik \"The Implementor\"", "Sehgal" ] => [ "Nik", "Sehgal" ],
        [ "Bis", "Sandilya, MBA, CSPO®" ] => [ "Bis", "Sandilya" ],
        [ "Jodie", "Crouch PRINCE2, PSM I" ] => [ "Jodie", "Crouch" ],
        [ "Monalisa", "Patel (She/Her)" ] => [ "Monalisa", "Patel" ],
        [ "Sara", "Lilja / fd von Schedvin" ] => [ "Sara", "Lilja" ],
        [ "Jimmy", "Wenham ☁️" ] => [ "Jimmy", "Wenham" ],
        [ "Joy, ", "BASIL" ] => [ "Joy", "BASIL" ],
        [ "Kiisha", "O’Connor" ] => [ "Kiisha", "O’Connor" ]
      }.each do |(first, last), cleaned|
        expect([ described_class.clean_name(first), described_class.clean_name(last, last: true) ]).to eq(cleaned)
      end
    end

    it "Keeps a profile listed twice once, and takes a last name alone as the first name" do
      text = csv("Anna,Andersson,https://www.linkedin.com/in/anna,,,,05 Oct 2026",
                 "Anna,Andersson,https://www.linkedin.com/in/anna,,,,05 Oct 2026",
                 ",Mononym,https://www.linkedin.com/in/mono,,,,bad date")
      entries = scan(text).connections

      expect(entries.size).to eq(2)
      expect(entries.last).to include("first_name" => "Mononym", "last_name" => nil, "connected_on" => nil, "suggested" => [])
    end

    it "Ignores a deleted Assignment and another user's" do
      assignment.update!(deleted_at: Time.current)
      create(:dossier_assignment, client: plotlogic, start_on: Date.new(2023, 2, 1), end_on: Date.new(2024, 8, 1),
                                  engagement: create(:dossier_engagement, employer: plotlogic, start_on: Date.new(2023, 2, 1),
                                                                          end_on: Date.new(2024, 8, 1)))

      expect(scan(csv("Bo,Berg,https://www.linkedin.com/in/bo,,Plotlogic,Developer,10 Jan 2024")).connections.sole["suggested"])
        .to eq([])
    end

    it "Reads a real zip with unzip" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "Connections.csv"), csv("Anna,Andersson,https://www.linkedin.com/in/anna,,,,05 Oct 2026"))
        system("zip", "-qj", File.join(dir, "export.zip"), File.join(dir, "Connections.csv"), exception: true)

        scan = described_class.new([ File.join(dir, "missing.zip"), File.join(dir, "export.zip") ], user: charlie)
        expect(scan.connections.map { |entry| entry["last_name"] }).to eq([ "Andersson" ])
      end
    end
  end
end
