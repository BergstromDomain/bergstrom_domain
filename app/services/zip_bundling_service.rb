# app/services/zip_bundling_service.rb

require "zip"

# App-agnostic zip bundler — takes a { filename => binary_content } hash and
# returns zip bytes. No knowledge of what's inside each entry (PDFs today,
# potentially any file type for a future export format).
class ZipBundlingService
  def initialize(entries)
    @entries = entries
  end

  def generate
    Zip::OutputStream.write_buffer do |zip|
      @entries.each do |filename, content|
        zip.put_next_entry(filename)
        zip.write(content)
      end
    end.string
  end
end
