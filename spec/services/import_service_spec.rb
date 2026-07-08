# spec/services/import_service_spec.rb
require "rails_helper"

RSpec.describe ImportService do
  let(:user) { create(:user, :content_creator) }

  def csv_file(contents)
    file = Tempfile.new([ "import", ".csv" ])
    file.write(contents)
    file.rewind
    file
  end

  describe "Happy path" do
    it "Returns the correct imported_count and failed_count" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-03
        Lars,Ulrich,Birthday,Lars's Birthday,1963-12-26
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(2)
      expect(result.failed_count).to eq(0)
      expect(result.errors).to be_empty
    end

    it "Parses zero-padded month and day as base-10 integers, not octal" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-09
      CSV

      ImportService.new(user, csv).import

      event = Event.find_by(title: "James's Birthday")
      expect(event.month).to eq(8)
      expect(event.day).to eq(9)
    end

    it "Finds an existing person instead of creating a duplicate" do
      create(:event_type, name: "Birthday")
      create(:person, user: user, first_name: "James", last_name: "Hetfield")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-03
      CSV

      expect {
        ImportService.new(user, csv).import
      }.not_to change(Person, :count)
    end

    it "Adds the person to an existing event instead of creating a duplicate" do
      birthday = create(:event_type, name: "Birthday")
      create(:event, user: user, event_type: birthday, title: "James's Birthday", day: 3, month: 8, year: 1963)
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-03
      CSV

      expect {
        ImportService.new(user, csv).import
      }.not_to change(Event, :count)

      expect(Event.find_by(title: "James's Birthday").people.map(&:first_name)).to include("James")
    end

    it "Assigns current_user as owner of all created records" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-03
      CSV

      ImportService.new(user, csv).import

      expect(Person.find_by(first_name: "James").user).to eq(user)
      expect(Event.find_by(title: "James's Birthday").user).to eq(user)
    end
  end

  describe "Negative path" do
    it "Produces a failed row with a meaningful message for an unknown event type" do
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        Kirk,Hammett,MadeUpType,Kirk's Mystery Event,1962-11-18
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(1)
      expect(result.errors.first[:row]).to eq(2)
      expect(result.errors.first[:message]).to include("MadeUpType")
    end

    it "Produces a failed row for an invalid date such as Feb 30" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-02-30
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(1)
    end

    it "Produces a failed row for a blank first name" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        ,Hetfield,Birthday,James's Birthday,1963-08-03
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(1)
    end
  end

  describe "Alternative path" do
    it "Imports successfully with a blank year, storing year as nil" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,-08-03
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(1)
      event = Event.find_by(title: "James's Birthday")
      expect(event.year).to be_nil
      expect(event.month).to eq(8)
      expect(event.day).to eq(3)
    end
  end

  describe "Edge cases" do
    it "Runs each row in its own transaction so one failure doesn't roll back others" do
      create(:event_type, name: "Birthday")
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
        James,Hetfield,Birthday,James's Birthday,1963-08-03
        Kirk,Hammett,MadeUpType,Kirk's Mystery Event,1962-11-18
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(1)
      expect(result.failed_count).to eq(1)
      expect(Person.find_by(first_name: "James")).to be_present
    end

    it "Returns 0 imported and 0 failed for a headers-only CSV" do
      csv = csv_file(<<~CSV)
        First name,Last name,Event type,Event title,Event date
      CSV

      result = ImportService.new(user, csv).import

      expect(result.imported_count).to eq(0)
      expect(result.failed_count).to eq(0)
    end
  end
end
