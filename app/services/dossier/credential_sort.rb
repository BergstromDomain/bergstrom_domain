# app/services/dossier/credential_sort.rb

# Sorts Credentials by a table column, from the page's ?sort=&direction=. An
# unknown column keeps the given order; an unknown direction is ascending.
# Blanks (no provider, no dates, no Skills) sort last either way. Taken
# During sorts by the label the table shows, given as taken_during.
class Dossier::CredentialSort
  COLUMNS = { "title" => "Title", "provider" => "Issued By", "dates" => "Dates",
              "taken_during" => "Taken During", "skills" => "Skills" }.freeze

  attr_reader :column, :direction

  def initialize(column, direction, taken_during:)
    @column = COLUMNS.key?(column) ? column : nil
    @direction = direction == "desc" ? "desc" : "asc"
    @taken_during = taken_during
  end

  def active?(column) = @column == column

  def apply(credentials)
    return credentials.to_a if @column.nil?

    present, blank = credentials.partition { |credential| key(credential) }
    present.sort_by! { |credential| key(credential) }
    present.reverse! if @direction == "desc"
    present + blank
  end

  private

  def key(credential)
    case @column
    when "title"        then credential.title.downcase
    when "provider"     then credential.provider&.short_name&.downcase
    when "dates"        then credential.start_on && [ credential.end_on || Date.new(9999), credential.start_on ]
    when "taken_during" then @taken_during.call(credential).downcase
    when "skills"       then credential.current_skills.first&.display_name&.downcase
    end
  end
end
