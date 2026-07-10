# app/services/import_template_service.rb
require "csv"

class ImportTemplateService
  def generate_csv
    CSV.generate(headers: true, encoding: "UTF-8") do |csv|
      csv << ImportService::HEADERS

      EventType.order("LOWER(name)").each do |event_type|
        csv << [ "[First name]", "[Last name]", event_type.name, "[Event title]", "YYYY-MM-DD" ]
      end
    end
  end
end
