# spec/services/dossier/course_scan_spec.rb
require "rails_helper"

# Turns a folder of course material (<Provider>/<Group…>/<Course>/Certificates)
# into the course manifest the import applies.
RSpec.describe Dossier::CourseScan do
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:texts) { {} }

  after { FileUtils.remove_entry(root) }

  def touch(relative, time: Time.zone.local(2022, 3, 15))
    path = root.join(relative)
    path.dirname.mkpath
    FileUtils.touch(path)
    File.utime(time.to_time, time.to_time, path)
    path
  end

  def certificate(relative, text: nil, **options)
    path = touch(relative, **options)
    texts[path.to_s] = text
    path
  end

  def scan(**options)
    described_class.new(root, text_of: ->(path) { texts[path.to_s] }, tracker_urls: {}, **options).courses
  end

  def course(title) = scan.find { |entry| entry["title"] == title }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Reads a LinkedIn Learning certificate: title, completion day and certificate number" do
      certificate("LinkedIn Learning/Agile/Scrum_Advanced/Certificates/CertificateOfCompletion_Scrum Advanced.pdf",
                  text: "Certificate of Completion\nCongratulations, Niklas Bergstrom\nScrum: Advanced\n" \
                        "Course completed on Sep 6, 2018\nCertificate No: AZNT_856 | PDU: 1.00")

      expect(course("Scrum: Advanced")).to eq(
        "title" => "Scrum: Advanced", "provider" => "LinkedIn Learning", "folder" => "LinkedIn Learning/Agile/Scrum_Advanced",
        "status" => "completed", "started" => "2018-09-06", "completed" => "2018-09-06", "precision" => "day",
        "certificate_number" => "AZNT_856", "verification_url" => nil, "skills" => [],
        "certificates" => [ "LinkedIn Learning/Agile/Scrum_Advanced/Certificates/CertificateOfCompletion_Scrum Advanced.pdf" ]
      )
    end

    it "Marks a course without a certificate In Progress, started when its oldest file was" do
      touch("LinkedIn Learning/DevOps/Learning_Chef/Exercise_Files/a.txt", time: Time.zone.local(2021, 6, 9))
      touch("LinkedIn Learning/DevOps/Learning_Chef/Summary/b.md", time: Time.zone.local(2022, 1, 2))

      expect(course("Learning Chef")).to include("status" => "in_progress", "started" => "2021-06-01", "completed" => nil,
                                                 "precision" => "month", "certificates" => [])
    end

    it "Tags Skills whose names appear in the title" do
      create(:dossier_skill, name: "Docker")
      create(:dossier_skill, name: "Do")
      touch("LinkedIn Learning/DevOps/Learning_Docker/Summary/notes.md")

      expect(course("Learning Docker")["skills"]).to eq([ "Docker" ])
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Skips Meetups, Seminars, templates and empty folders" do
      touch("Meetups/Elabor8 Lunch and Learn/Wardley/notes.md")
      touch("Seminars/AWS - Modern Application Development/slides.pdf")
      touch("LinkedIn Learning/_TEMPLATE_/Summary/notes.md")
      root.join("Udemy/Python").mkpath

      expect(scan).to be_empty
    end

    it "Leaves out progress reports, attaching only the certificate" do
      certificate("Skillsoft/Development/Beginner Git/Certificates/Certificate of Completion - Beginner Git.pdf",
                  text: "13/11/2017 Certificate of Completion\nhas completed the course\nBeginner Git - sd_gitf_a01_it_enus\non\nNov 13, 2017")
      certificate("Skillsoft/Development/Beginner Git/Certificates/Completion Status Report - Beginner Git.pdf")
      certificate("Skillsoft/Development/Beginner Git/Certificates/Player Results Information.pdf")

      expect(course("Beginner Git")).to include(
        "provider" => "Skillsoft", "completed" => "2017-11-13",
        "certificates" => [ "Skillsoft/Development/Beginner Git/Certificates/Certificate of Completion - Beginner Git.pdf" ]
      )
    end
  end

  # 3) Alternative Path ───────────────────────────────────────────────────────
  describe "Alternative Path" do
    it "Takes a Udemy certificate's number and link from its file name, and its date from the file" do
      certificate("Udemy/Complete Ruby Programmer/Certificates/UC-V5E13AFR.pdf", time: Time.zone.local(2019, 4, 20))

      expect(course("Complete Ruby Programmer")).to include(
        "status" => "completed", "completed" => "2019-04-01", "precision" => "month", "certificate_number" => "UC-V5E13AFR",
        "verification_url" => "https://www.udemy.com/certificate/UC-V5E13AFR/"
      )
    end

    it "Reads a UiPath diploma's dd/mm/yy date" do
      certificate("UiPath/Development/Business Analyst/Certificate/636_94_1568262463_Business Analyst Diploma 2019.pdf",
                  text: "Niklas Bergstrom\n12/09/19\nPowered by TCPDF")

      expect(course("Business Analyst")).to include("provider" => "UiPath", "completed" => "2019-09-12")
    end

    it "Counts a folder holding its material directly as a course" do
      touch("Linux Training Academy/Shell Scripting/shell-scripting-book.pdf")
      touch("Linux Training Academy/Shell Scripting/Shellclass/notes.md")

      expect(scan.map { |entry| entry["title"] }).to eq([ "Shell Scripting" ])
    end
    it "Treats a group folder with notes of its own as a group, not a course" do
      touch("LinkedIn Learning/Agile/paths.xlsx")
      touch("LinkedIn Learning/Agile/Scrum_The_Basics/Summary/notes.md")
      touch("LinkedIn Learning/Agile/Scrum_Advanced/Summary/notes.md")

      expect(scan.map { |entry| entry["title"] }).to eq([ "Scrum Advanced", "Scrum The Basics" ])
    end
  end

  describe "Verification URLs from the course tracker" do
    let(:ods_xml) do
      <<~XML
        <office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:xlink="http://www.w3.org/1999/xlink">
          <office:body><office:spreadsheet><table:table>
            <table:table-row>
              <table:table-cell><text:p>Provider</text:p></table:table-cell>
              <table:table-cell><text:p>Course</text:p></table:table-cell>
              <table:table-cell><text:p>Verification URL</text:p></table:table-cell>
            </table:table-row>
            <table:table-row>
              <table:table-cell><text:p>LinkedIn Learning</text:p></table:table-cell>
              <table:table-cell><text:p>Scrum The Basics</text:p></table:table-cell>
              <table:table-cell><text:p>https://www.linkedin.com/learning/certificates/abc</text:p></table:table-cell>
            </table:table-row>
            <table:table-row>
              <table:table-cell table:number-columns-repeated="2"><text:p>x</text:p></table:table-cell>
              <table:table-cell/>
            </table:table-row>
            <table:table-row>
              <table:table-cell><text:p>LinkedIn Learning</text:p></table:table-cell>
              <table:table-cell><text:p><text:a xlink:href="https://www.linkedin.com/learning/certificates/def">Scrum Advanced</text:a></text:p></table:table-cell>
              <table:table-cell/>
            </table:table-row>
          </table:table></office:spreadsheet></office:body>
        </office:document-content>
      XML
    end

    it "Reads each course's URL from a URL column or the row's link" do
      expect(described_class.tracker_urls(ods_xml)).to eq(
        "scrumthebasics" => "https://www.linkedin.com/learning/certificates/abc",
        "scrumadvanced" => "https://www.linkedin.com/learning/certificates/def"
      )
    end

    it "Fills in a course's Verification URL from the tracker, matching the title without punctuation" do
      certificate("LinkedIn Learning/Agile/Scrum_The_Basics/Certificates/c.pdf",
                  text: "Congratulations, Niklas Bergstrom\nScrum: The Basics\nCourse completed on Sep 10, 2018")
      urls = described_class.tracker_urls(ods_xml)

      expect(scan(tracker_urls: urls).first["verification_url"]).to eq("https://www.linkedin.com/learning/certificates/abc")
    end

    it "Reads the tracker in the root folder with unzip, and nothing when unzip is missing or fails" do
      touch(described_class::TRACKER)
      ok = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2).with("unzip", "-p", root.join(described_class::TRACKER).to_s, "content.xml")
                                        .and_return([ ods_xml, ok ])
      expect(described_class.new(root).send(:tracker_urls_in, root)).to include("scrumadvanced")

      allow(Open3).to receive(:capture2).and_return([ "", instance_double(Process::Status, success?: false) ])
      expect(described_class.new(root).send(:tracker_urls_in, root)).to eq({})
      allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)
      expect(described_class.new(root).send(:tracker_urls_in, root)).to eq({})
    end

    it "Finds no URLs in a tracker without them, or without a tracker" do
      xml = ods_xml.gsub(%r{https://[^<"]+}, "").gsub("Verification URL", "Notes")

      expect(described_class.tracker_urls(xml)).to eq({})
      expect(described_class.new(root).send(:tracker_urls_in, root)).to eq({})
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Merges folders of the same course, keeping one copy of each certificate" do
      certificate("LinkedIn Learning/Test/Jira/JIRA Software Basic Administration/Certificates/CertificateOfCompletion_Jira.pdf",
                  text: "Congratulations, Niklas Bergstrom\nJIRA Software: Basic Administration\nCourse completed on Mar 1, 2018")
      certificate("LinkedIn Learning/Test/Jira/JIRA_Software_Basic_Administration/Certificates/CertificateOfCompletion_Jira.pdf",
                  text: "Congratulations, Niklas Bergstrom\nJIRA Software: Basic Administration\nCourse completed on Mar 1, 2018")

      entries = scan
      expect(entries.size).to eq(1)
      expect(entries.first["certificates"].size).to eq(1)
    end

    it "Joins a title that wraps onto a second line, and drops a Skillsoft course code after a soft hyphen" do
      certificate("LinkedIn Learning/AWS/AWS_Devs/Certificates/c.pdf",
                  text: "Congratulations, Niklas Bergstrom\nLearning Amazon Web Services (AWS) for\nDevelopers\n" \
                        "Course completed on Nov 21, 2018")
      certificate("Skillsoft/Agile/APM/Certificates/c.pdf",
                  text: "has completed the course\nAgile Project Management Essentials \u00AD ib_pmag_a01_it_enus\non\nAug 3, 2016")

      expect(scan.map { |entry| entry["title"] })
        .to eq([ "Learning Amazon Web Services (AWS) for Developers", "Agile Project Management Essentials" ])
    end

    it "Reads a PDF's text with pdftotext, dropping blank lines, and nothing from other files or without pdftotext" do
      scan = described_class.new(root)
      pdf = Pathname("certificate.pdf")
      allow(Open3).to receive(:capture2).and_return([ "Scrum: Advanced\n\n  Course completed on Sep 6, 2018 \n", instance_double(Process::Status, success?: true) ])

      expect(scan.send(:pdf_text, pdf)).to eq("Scrum: Advanced\nCourse completed on Sep 6, 2018")
      expect(scan.send(:pdf_text, Pathname("notes.md"))).to be_nil
      allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)
      expect(scan.send(:pdf_text, pdf)).to be_nil
    end

    it "Has no provider for Misc, and falls back to the file date when a certificate has no readable date" do
      certificate("Misc/Eclipse and Java for total beginners/Certificates/done.pdf", text: "Well done", time: Time.zone.local(2015, 8, 3))

      expect(course("Eclipse and Java for total beginners")).to include("provider" => nil, "completed" => "2015-08-01",
                                                                        "precision" => "month")
    end
  end
end
