# app/controllers/events_controller.rb
class EventsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_event,        only: %i[show edit update destroy]
  before_action :require_creator!, only: %i[edit update destroy]

  def index
    @events = if authenticated?
                Event.visible_to_users.chronological
    else
                Event.visible_to_visitors.chronological
    end
  end

  def show
    unless @event.unrestricted? || authenticated?
      redirect_to events_path, alert: "You do not have permission to view that event."
    end
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.user = Current.user
    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event was successfully deleted."
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def require_creator!
    unless @event.user == Current.user
      redirect_to @event, alert: "You do not have permission to modify that event."
    end
  end

  def event_params
    params.require(:event).permit(
      :event_type_id, :title, :description, :day, :month, :year,
      :image, :thumbnail_image, :classification, person_ids: []
    )
  end
end
