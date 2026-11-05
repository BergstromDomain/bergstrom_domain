# spec/support/docx_helpers.rb

require "zip"

# Reads a generated .docx (a zip of XML parts) so specs can check what Word
# will show: docx_parts gives every part's XML by name; docx_paragraphs gives
# word/document.xml's paragraphs as [style id, text] pairs, in order.
module DocxHelpers
  W = { "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main" }.freeze

  def docx_parts(data)
    parts = {}
    Zip::InputStream.open(StringIO.new(data)) do |io|
      while (entry = io.get_next_entry)
        parts[entry.name] = io.read.force_encoding("UTF-8")
      end
    end
    parts
  end

  def docx_paragraphs(data)
    document = Nokogiri::XML(docx_parts(data).fetch("word/document.xml"))
    document.xpath("//w:body/w:p", W).map do |paragraph|
      [ paragraph.at_xpath("w:pPr/w:pStyle/@w:val", W)&.value, paragraph.xpath(".//w:t", W).map(&:text).join ]
    end
  end
end

RSpec.configure do |config|
  config.include DocxHelpers
end
