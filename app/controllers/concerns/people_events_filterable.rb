# app/controllers/concerns/people_events_filterable.rb

# Shared Basic/SQL filtering orchestration for any controller that needs "the
# person+event rows the current viewer can see, narrowed by the Filter People
# and Events params" — mirrors BlogPostFilterable, shared by
# PeopleEventsController (Filter page) and PeopleEventsExportsController (its
# Download page reuses the exact same filter UI/engine so a download always
# matches what's on screen).
module PeopleEventsFilterable
  extend ActiveSupport::Concern

  private

  def compute_filtered_people_events_rows
    rows = all_rows

    @mode  = params[:mode] == "sql" ? "sql" : "basic"
    @query = params[:query].to_s
    @filter_error = nil
    @rows = rows

    begin
      ast =
        if @mode == "sql"
          @query.presence && Jql::Parser.parse(@query)
        else
          PersonEventFilter.basic_ast(**basic_filter_params)
        end

      if ast
        PersonEventFilter::EVALUATOR.validate!(ast)
        @rows = rows.select { |row| PersonEventFilter::EVALUATOR.matches?(ast, PersonEventFilter.attributes_for(row)) }
      end
    rescue Jql::ParseError => e
      @filter_error = e.message
      @rows = []
    end

    set_filter_options(rows)
  end

  def all_rows
    events_by_person_id = visible_events_scope.includes(:event_type, :people)
      .order("year ASC NULLS LAST, month ASC, day ASC")
      .each_with_object(Hash.new { |h, k| h[k] = [] }) do |event, by_person|
        event.people.each { |person| by_person[person.id] << event }
      end

    visible_people_scope.order("LOWER(last_name), LOWER(first_name)").flat_map do |person|
      events = events_by_person_id[person.id] || []
      if events.empty?
        [ PersonEventFilter::Row.new(person: person, event: nil) ]
      else
        events.map { |event| PersonEventFilter::Row.new(person: person, event: event) }
      end
    end
  end

  def visible_people_scope
    if !authenticated?
      Person.visible_to_visitors
    elsif current_user.can_administer?
      Person.visible_to_admins
    else
      Person.visible_to_users(current_user)
    end
  end

  def visible_events_scope
    if !authenticated?
      Event.visible_to_visitors
    elsif current_user.can_administer?
      Event.visible_to_admins
    else
      Event.visible_to_users(current_user)
    end
  end

  def basic_filter_params
    {
      first_name:     params[:first_name].presence,
      last_name:      params[:last_name].presence,
      event_type:     params[:event_type].presence,
      title:          params[:title].presence,
      date_range:     date_range_for(params[:date]),
      classification: params[:classification].presence
    }
  end

  def date_range_for(value)
    case value
    when "today"      then Date.current..Date.current
    when "this_week"  then Date.current.beginning_of_week..Date.current
    when "this_month" then Date.current.beginning_of_month..Date.current
    when "this_year"  then Date.current.beginning_of_year..Date.current
    end
  end

  def set_filter_options(rows)
    @first_name_options = rows.map { |row| row.person.first_name }.compact_blank.uniq.sort
    @last_name_options   = rows.map { |row| row.person.last_name }.compact_blank.uniq.sort
    @event_type_options  = rows.filter_map { |row| row.event&.event_type&.name }.uniq.sort
    @title_options        = rows.filter_map { |row| row.event&.title }.uniq.sort
  end
end
