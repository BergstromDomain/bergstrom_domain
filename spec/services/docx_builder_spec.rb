# spec/services/docx_builder_spec.rb

require "rails_helper"

RSpec.describe DocxBuilder do
  let(:builder) { described_class.new(title: "Alex Example — CV", author: "Alex Example", footer: "Alex Example") }

  # 1) Happy Path ─────────────────────────────────────────────────────────────
  describe "Happy Path" do
    it "Writes a Word package with its document, styles, bullets and footer" do
      parts = docx_parts(builder.paragraph("Hello").to_docx)

      expect(parts.keys.first).to eq("[Content_Types].xml")
      expect(parts.keys).to include("_rels/.rels", "word/document.xml", "word/_rels/document.xml.rels",
                                    "word/styles.xml", "word/numbering.xml", "word/footer1.xml", "docProps/core.xml")
      parts.each_value { |xml| expect(Nokogiri::XML(xml).errors).to be_empty }
    end

    it "Writes paragraphs in order, each with its style" do
      data = builder.paragraph("Alex Example", style: "Title")
                    .paragraph("Experience", style: "Heading1")
                    .paragraph("Ran daily defect triage", style: "ListBullet")
                    .to_docx

      expect(docx_paragraphs(data)).to eq([ [ "Title", "Alex Example" ], [ "Heading1", "Experience" ],
                                            [ "ListBullet", "Ran daily defect triage" ] ])
    end

    it "Writes bold runs within a paragraph" do
      xml = docx_parts(builder.paragraph([ [ "Test Tools:", { bold: true } ], [ " Jira" ] ]).to_docx).fetch("word/document.xml")
      runs = Nokogiri::XML(xml).xpath("//w:r", DocxHelpers::W)

      expect(runs.map(&:text)).to eq([ "Test Tools:", " Jira" ])
      expect(runs.first.at_xpath("w:rPr/w:b", DocxHelpers::W)).to be_present
      expect(runs.last.at_xpath("w:rPr/w:b", DocxHelpers::W)).to be_nil
    end

    it "Puts the footer text and page numbers in the footer, and the title and author in the properties" do
      parts = docx_parts(builder.to_docx)

      expect(parts.fetch("word/footer1.xml")).to include("Alex Example · Page", "PAGE", "NUMPAGES")
      expect(parts.fetch("docProps/core.xml")).to include("<dc:title>Alex Example — CV</dc:title>",
                                                          "<dc:creator>Alex Example</dc:creator>")
    end
  end

  # 2) Negative Path ──────────────────────────────────────────────────────────
  describe "Negative Path" do
    it "Rejects a style the styles part doesn't define" do
      expect { builder.paragraph("Hello", style: "NoSuchStyle") }.to raise_error(ArgumentError, /NoSuchStyle/)
    end
  end

  # 3) Alternative Paths ───────────────────────────────────────────────────────
  describe "Alternative Paths" do
    it "Writes a paragraph with no style as Normal (no style element)" do
      expect(docx_paragraphs(builder.paragraph("Plain").to_docx)).to eq([ [ nil, "Plain" ] ])
    end

    it "Sets an A4 page" do
      xml = docx_parts(builder.to_docx).fetch("word/document.xml")

      expect(xml).to include('w:w="11906"', 'w:h="16838"')
    end
  end

  # 4) Edge Cases ─────────────────────────────────────────────────────────────
  describe "Edge Cases" do
    it "Escapes XML in text and keeps its spaces" do
      data = builder.paragraph("Tom & Jerry <script> \"quoted\"  ").to_docx

      expect(docx_paragraphs(data)).to eq([ [ nil, "Tom & Jerry <script> \"quoted\"  " ] ])
      expect(docx_parts(data).fetch("word/document.xml")).to include('xml:space="preserve"')
    end

    it "Drops control characters XML can't hold" do
      expect(docx_paragraphs(builder.paragraph("Bell\aTab\tok").to_docx)).to eq([ [ nil, "BellTab\tok" ] ])
    end

    it "Writes a valid document with no paragraphs" do
      xml = docx_parts(builder.to_docx).fetch("word/document.xml")

      expect(Nokogiri::XML(xml).errors).to be_empty
    end
  end
end
