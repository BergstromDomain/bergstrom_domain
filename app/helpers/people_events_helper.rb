# app/helpers/people_events_helper.rb
module PeopleEventsHelper
  FILTER_SORT_LABELS = {
    "first_name" => "First Name",
    "last_name"  => "Last Name",
    "event_type" => "Event Type",
    "title"      => "Event Title",
    "date"       => "Event Date"
  }.freeze

  # A sortable column header link for the Filter/Download results table —
  # preserves every other current query param (mode/query/first_name/etc.)
  # and toggles direction when the same column is clicked again. Mirrors
  # BlogPostsHelper#filter_sort_link.
  def people_events_filter_sort_link(column, path_helper:)
    next_direction = (@sort == column && @direction == "asc") ? "desc" : "asc"
    query = request.query_parameters.merge("sort" => column, "direction" => next_direction)
    arrow = @sort == column ? (@direction == "asc" ? " ▲" : " ▼") : ""

    link_to "#{FILTER_SORT_LABELS.fetch(column)}#{arrow}", send(path_helper, query),
      data: { testid: "sort-#{column}" }
  end
end
