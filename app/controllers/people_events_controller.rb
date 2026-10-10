# app/controllers/people_events_controller.rb

# A single-action controller for the combined "Filter People and Events" page
# — mirrors BlogPostsController#filter, but there's no single "the resource"
# here the way BlogPost is for Chronicle (People and Events are two separate
# top-level resources in Occasions), so this gets its own thin controller
# rather than living on PeopleController or EventsController.
class PeopleEventsController < ApplicationController
  include Navigable
  include PeopleEventsFilterable

  FILTER_SORT_COLUMNS = %w[first_name last_name event_type title date classification].freeze

  allow_unauthenticated_access only: %i[ filter ]
  before_action :resume_session_if_available, only: %i[ filter ]

  def filter
    compute_filtered_people_events_rows

    @sort      = FILTER_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "last_name"
    @direction = params[:direction] == "desc" ? "desc" : "asc"
    @rows = PersonEventFilter.sort(@rows, @sort, @direction)
  end

  private

  def resume_session_if_available
    resume_session
  end
end
