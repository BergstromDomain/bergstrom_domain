# app/services/docx_builder.rb

# App-agnostic Word (.docx) writer: paragraphs, each with a named style and
# optional bold runs, packed with ZipBundlingService into the handful of
# OOXML parts Word needs. The look lives entirely in a styles part
# (config/docx/*_styles.xml, word/styles.xml as Word itself writes it), so a
# style can be redesigned in Word without touching Ruby. Every page gets a
# centred "<footer> · Page X of Y" footer, and the page is A4.
#
#   DocxBuilder.new(title: "CV", author: "Alex", footer: "Alex")
#              .paragraph("Alex Example", style: "Title")
#              .paragraph([ [ "Test Tools:", { bold: true } ], [ " Jira" ] ])
#              .to_docx
class DocxBuilder
  CLASSIC_STYLES = Rails.root.join("config/docx/classic_styles.xml")

  W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"

  # Characters XML 1.0 can't hold (all C0 controls but tab, newline, return).
  INVALID_XML = /[\x00-\x08\x0B\x0C\x0E-\x1F]/

  def initialize(title:, author:, footer:, styles: CLASSIC_STYLES)
    @title = title
    @author = author
    @footer = footer
    @styles = File.read(styles)
    @style_ids = Nokogiri::XML(@styles).xpath("//w:style/@w:styleId", "w" => W_NS).map(&:value)
    @paragraphs = []
  end

  # text is a String, or runs: [[text, { bold: true }], [text], …]. Returns
  # self, so calls chain.
  def paragraph(text, style: nil)
    raise ArgumentError, "Unknown style #{style.inspect}" if style && !@style_ids.include?(style)

    runs = text.is_a?(String) ? [ [ text ] ] : text
    @paragraphs << paragraph_xml(runs, style)
    self
  end

  def to_docx
    ZipBundlingService.new(
      "[Content_Types].xml"          => content_types,
      "_rels/.rels"                  => package_rels,
      "docProps/core.xml"            => core_properties,
      "word/document.xml"            => document,
      "word/_rels/document.xml.rels" => document_rels,
      "word/styles.xml"              => @styles,
      "word/numbering.xml"           => numbering,
      "word/footer1.xml"             => footer
    ).generate
  end

  private

  def escape(text) = ERB::Util.html_escape(text.to_s.gsub(INVALID_XML, ""))

  def paragraph_xml(runs, style)
    properties = style ? %(<w:pPr><w:pStyle w:val="#{style}"/></w:pPr>) : ""
    "<w:p>#{properties}#{runs.map { |text, options| run_xml(text, **(options || {})) }.join}</w:p>"
  end

  def run_xml(text, bold: false)
    properties = bold ? "<w:rPr><w:b/></w:rPr>" : ""
    %(<w:r>#{properties}<w:t xml:space="preserve">#{escape(text)}</w:t></w:r>)
  end

  def xml(body) = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n#{body})

  def content_types
    xml(<<~XML)
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
        <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
        <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
        <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
      </Types>
    XML
  end

  def package_rels
    xml(<<~XML)
      <Relationships xmlns="#{PKG_REL_NS}">
        <Relationship Id="rId1" Type="#{REL_NS}/officeDocument" Target="word/document.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
      </Relationships>
    XML
  end

  def core_properties
    xml(<<~XML)
      <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                         xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:title>#{escape(@title)}</dc:title>
        <dc:creator>#{escape(@author)}</dc:creator>
      </cp:coreProperties>
    XML
  end

  def document_rels
    xml(<<~XML)
      <Relationships xmlns="#{PKG_REL_NS}">
        <Relationship Id="rId1" Type="#{REL_NS}/styles" Target="styles.xml"/>
        <Relationship Id="rId2" Type="#{REL_NS}/numbering" Target="numbering.xml"/>
        <Relationship Id="rId3" Type="#{REL_NS}/footer" Target="footer1.xml"/>
      </Relationships>
    XML
  end

  # A4 (in twentieths of a point), margins 18/16/20 mm like the PDF.
  def document
    xml(<<~XML)
      <w:document xmlns:w="#{W_NS}" xmlns:r="#{R_NS}">
        <w:body>
          #{@paragraphs.join("\n    ")}
          <w:sectPr>
            <w:footerReference w:type="default" r:id="rId3"/>
            <w:pgSz w:w="11906" w:h="16838"/>
            <w:pgMar w:top="1020" w:right="907" w:bottom="1134" w:left="907" w:header="567" w:footer="510" w:gutter="0"/>
          </w:sectPr>
        </w:body>
      </w:document>
    XML
  end

  # One bullet list definition (numId 1), used by the ListBullet style.
  def numbering
    xml(<<~XML)
      <w:numbering xmlns:w="#{W_NS}">
        <w:abstractNum w:abstractNumId="0">
          <w:multiLevelType w:val="singleLevel"/>
          <w:lvl w:ilvl="0">
            <w:start w:val="1"/>
            <w:numFmt w:val="bullet"/>
            <w:lvlText w:val="•"/>
            <w:lvlJc w:val="left"/>
            <w:pPr><w:ind w:left="284" w:hanging="284"/></w:pPr>
          </w:lvl>
        </w:abstractNum>
        <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
      </w:numbering>
    XML
  end

  def field(code)
    %(<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> #{code} </w:instrText></w:r>) +
      %(<w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>)
  end

  def footer
    xml(<<~XML)
      <w:ftr xmlns:w="#{W_NS}" xmlns:r="#{R_NS}">
        <w:p>
          <w:pPr><w:pStyle w:val="Footer"/></w:pPr>
          #{run_xml("#{@footer} · Page ")}#{field('PAGE')}#{run_xml(' of ')}#{field('NUMPAGES')}
        </w:p>
      </w:ftr>
    XML
  end
end
