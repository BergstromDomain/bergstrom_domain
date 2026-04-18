# app/controllers/events_controller.rb
class EventsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_available, only: %i[index show]
  before_action :set_event,    only: %i[show edit update destroy]
  before_action :set_policy,   only: %i[new create edit update destroy]

  def index
    @events = if !authenticated?
                Event.visible_to_visitors
              elsif current_user.can_administer?
                Event.visible_to_admins
              else
                Event.visible_to_users(current_user)
              end.chronological
  end

  def show
    @policy = Policy.new(current_user, @event)
    unless @policy.can_read?
      redirect_to events_path, alert: "You do not have permission to view that event."
    end
  end

  def new
    @event = Event.new
  end

  def create
    unless @policy.can_create?
      redirect_to events_path, alert: "You do not have permission to create events."
      return
    end

    @event = Event.new(event_params)
    @event.user = current_user
    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @policy.can_update?
      redirect_to @event, alert: "You do not have permission to modify that event."
    end
  end

  def update
    unless @policy.can_update?
      redirect_to @event, alert: "You do not have permission to modify that event."
      return
    end

    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to @event, alert: "You do not have permission to delete that event."
      return
    end

    @event.destroy
    redirect_to events_path, notice: "Event was successfully deleted."
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def set_policy
    resource = @event || :event_tracker
    @policy  = Policy.new(current_user, resource)
  end

  def resume_session_if_available
    resume_session
  end

  def event_params
    params.require(:event).permit(
      :event_type_id, :title, :description, :day, :month, :year,
      :image, :thumbnail_image, :classification, person_ids: []
    )
  end
end
