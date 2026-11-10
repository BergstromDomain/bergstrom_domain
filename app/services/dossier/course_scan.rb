# app/services/dossier/course_scan.rb

# Turns a folder of course material into the course manifest that
# Dossier::CourseImport applies, for review in between. The layout:
# <Provider>/<Group…>/<Course>/, a course folder being one with material
# folders (Certificates, Lessons, Summary…) or files of its own. Meetups,
# Seminars, templates and empty folders are skipped; Misc has no provider.
#
# A course with a certificate is Completed: its title, completion date and
# certificate number come from the PDF's text when it has them (LinkedIn
# Learning, Skillsoft, UiPath), else from the folder name and the file's date
# (a Udemy certificate's number and link come from its file name). One without
# is In Progress, started when its oldest file was. Skills are the existing
# ones named in the title. Folders of the same course merge into one.
class Dossier::CourseScan
  SKIPPED = %w[Meetups Seminars _TEMPLATE_ _gsdata_].freeze
  NO_PROVIDER = %w[Misc].freeze
  CERTIFICATE_FOLDERS = %w[Certificate Certificates Certifications].freeze
  MATERIAL_FOLDERS = (CERTIFICATE_FOLDERS + [ "Lessons", "Summary", "Course summary", "References", "Src", "Images",
                                              "Exercise_Files", "Skillsoft" ]).freeze
  NOT_CERTIFICATES = /Player Results|Completion Status Report/i
  MONTH_DATE = /\b([A-Z][a-z]{2,8} \d{1,2}, \d{4})\b/
  SHORT_DATE = %r{\b(\d{2})/(\d{2})/(\d{2})\b}
  # Skill names that are also everyday words in course titles.
  COMMON_WORDS = %w[Project Teams].freeze
  UDEMY_NUMBER = /\A(UC-[A-Z0-9-]+)\.pdf\z/i

  # text_of: reads a PDF's text (pdftotext by default; nil when it has none).
  def initialize(root, text_of: method(:pdf_text))
    @root = Pathname(root)
    @text_of = text_of
  end

  # Manifest entries (string-keyed hashes), in folder order.
  def courses
    entries = provider_folders.flat_map { |folder| course_folders(folder).map { |course| entry(folder, course) } }
    entries.compact.group_by { |entry| [ entry["provider"], entry["title"].downcase ] }.values.map { |same| merge(same) }
  end

  def to_yaml = { "root" => @root.to_s, "courses" => courses }.to_yaml

  private

  def provider_folders = subfolders(@root)

  def subfolders(folder)
    folder.children.select(&:directory?).reject { |child| SKIPPED.include?(child.basename.to_s) }.sort
  end

  # A folder with material folders is a course. One holding such courses is
  # a group, even with notes of its own; otherwise one with files of its own
  # is a course, whatever its subfolders hold.
  def course_folders(folder) = found_courses(folder).map(&:first)

  # [[folder, by_material?]…]
  def found_courses(folder)
    subfolders(folder).flat_map do |child|
      next [ [ child, true ] ] if material?(child)

      inner = found_courses(child)
      inner.any?(&:last) || child.children.none?(&:file?) ? inner : [ [ child, false ] ]
    end
  end

  def material?(folder)
    folder.children.any? { |child| child.directory? && MATERIAL_FOLDERS.include?(child.basename.to_s) }
  end

  def entry(provider_folder, folder)
    files = folder.glob("**/*").select(&:file?).reject { |file| file.to_s.include?("/_gsdata_/") }
    return if files.empty?

    certificates = certificate_files(folder)
    text = certificates.filter_map { |file| @text_of.call(file) }.first.to_s
    title = title_from(text) || folder.basename.to_s.tr("_", " ").squeeze(" ").strip
    completed, precision = completion(text, certificates)
    started = completed || files.map(&:mtime).min.to_date.beginning_of_month
    number = text[/Certificate No:\s*(\S+)/, 1] || certificates.filter_map { |file| file.basename.to_s[UDEMY_NUMBER, 1] }.first

    { "title" => title, "provider" => provider_name(provider_folder), "folder" => relative(folder),
      "status" => certificates.any? ? "completed" : "in_progress",
      "started" => started.iso8601, "completed" => completed&.iso8601, "precision" => precision || "month",
      "certificate_number" => number,
      "verification_url" => (number.start_with?("UC-") ? "https://www.udemy.com/certificate/#{number}/" : nil if number),
      "skills" => skills_in(title), "certificates" => certificates.map { |file| relative(file) } }
  end

  def certificate_files(folder)
    folder.children.select { |child| child.directory? && CERTIFICATE_FOLDERS.include?(child.basename.to_s) }
          .flat_map { |dir| dir.glob("**/*").select(&:file?) }
          .reject { |file| file.basename.to_s.match?(NOT_CERTIFICATES) }.sort
  end

  # LinkedIn: the lines between "Congratulations, <name>" and "Course
  # completed on"; Skillsoft: between "has completed the course" and "on",
  # less its course code (after a hyphen or a soft hyphen).
  def title_from(text)
    lines = text.lines.map(&:strip).reject(&:empty?)
    between(lines, /\ACongratulations,/, /\ACourse completed on/) ||
      between(lines, /has completed the course/, /\Aon\z/)&.sub(/\s*[-\u00AD]\s*\w+_\w+\z/, "")
  end

  def between(lines, first, last)
    start = lines.index { |line| line.match?(first) }
    return unless start

    finish = lines.index.with_index { |line, index| index > start && line.match?(last) } || start + 2
    title = lines[(start + 1)...finish].join(" ").squeeze(" ").strip
    title.presence
  end

  # [date, precision]: from the certificate's text when it names a day, else
  # the certificate file's month; nil without a certificate.
  def completion(text, certificates)
    return if certificates.empty?

    if (match = text[MONTH_DATE, 1])
      [ Date.parse(match), "day" ]
    elsif (day, month, year = text.match(SHORT_DATE)&.captures)
      [ Date.new(2000 + year.to_i, month.to_i, day.to_i), "day" ]
    else
      [ certificates.map(&:mtime).min.to_date.beginning_of_month, "month" ]
    end
  end

  def merge(entries)
    entries.max_by { |entry| entry["status"] == "completed" ? 1 : 0 }.merge(
      "certificates" => entries.flat_map { |entry| entry["certificates"] }.uniq { |path| File.basename(path) }
    )
  end

  def provider_name(folder)
    name = folder.basename.to_s
    NO_PROVIDER.include?(name) ? nil : name
  end

  def skills_in(title)
    @skill_names ||= (Dossier::Skill.pluck(:name).uniq - COMMON_WORDS).select { |name| name.length > 2 }
    @skill_names.select { |name| title.match?(/(?<![\w])#{Regexp.escape(name)}(?![\w])/i) }.sort_by(&:downcase)
  end

  def relative(path) = path.relative_path_from(@root).to_s

  def pdf_text(path)
    return unless path.extname.casecmp?(".pdf")

    output, status = Open3.capture2("pdftotext", "-layout", path.to_s, "-")
    text = output.lines.map(&:strip).reject(&:empty?).join("\n")
    status.success? && text.present? ? text : nil
  rescue Errno::ENOENT
    nil
  end
end
