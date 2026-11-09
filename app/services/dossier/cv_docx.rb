# app/services/dossier/cv_docx.rb

# Lays a Dossier::CvDocument out as a Word file in the "Classic" style, in the
# same order and wording as the PDF (dossier/master_cvs/cv.html.erb): Title,
# Subtitle and Contacts for the header, Heading1 per section, Heading2 per
# Engagement, Heading3 per Assignment, Meta lines, Tech Stack lines and
# List Bullet Achievements.
class Dossier::CvDocx
  def initialize(cv)
    @cv = cv
  end

  def render
    name = @cv.header.name
    @doc = DocxBuilder.new(title: "#{name} — CV", author: name, footer: name)
    header
    jobs("Experience", @cv.experience)
    jobs("Personal Projects", @cv.personal_projects)
    skills
    credentials
    @doc.to_docx
  end

  private

  def header
    header = @cv.header
    @doc.paragraph(header.name, style: "Title")
    @doc.paragraph(header.headline, style: "Subtitle") if header.headline
    @doc.paragraph(header.contacts.join(" · "), style: "Contacts") if header.contacts.any?
    @doc.paragraph(@cv.summary) if @cv.summary
  end

  def jobs(heading, jobs)
    return if jobs.empty?

    @doc.paragraph(heading, style: "Heading1")
    jobs.each do |job|
      @doc.paragraph(job.title, style: "Heading2")
      @doc.paragraph([ job.organisation, job.employment_type, job.dates ].join(" · "), style: "Meta")
      @doc.paragraph(job.summary) if job.summary
      job.assignments.each { |assignment| assignment(assignment) }
    end
  end

  def assignment(assignment)
    if assignment.heading
      @doc.paragraph(assignment.heading, style: "Heading3")
      @doc.paragraph([ assignment.role, assignment.dates, assignment.location ].compact.join(" · "), style: "Meta")
    elsif assignment.location
      @doc.paragraph(assignment.location, style: "Meta")
    end
    @doc.paragraph(assignment.summary) if assignment.summary
    assignment.tech_stack.each { |label, names| labelled(label, names, style: "TechStack") }
    assignment.achievements.each { |achievement| @doc.paragraph(achievement, style: "ListBullet") }
  end

  def skills
    skills = @cv.skills
    return if skills.empty?

    @doc.paragraph("Skills", style: "Heading1")
    skills.each { |category, line| labelled(category, line) }
  end

  def credentials
    @cv.credentials.each do |section|
      @doc.paragraph(section.heading, style: "Heading1")
      section.entries.each do |credential|
        title = credential.expired ? "#{credential.title} (expired)" : credential.title
        details = [ credential.provider, credential.dates ].compact.join(" · ")
        @doc.paragraph([ [ title, { bold: true } ], [ " · #{details}" ] ])
      end
    end
  end

  # "Label: text", the label in bold.
  def labelled(label, text, style: nil)
    @doc.paragraph([ [ "#{label}:", { bold: true } ], [ " #{text}" ] ], style: style)
  end
end
