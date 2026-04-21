# app/controllers/event_types_controller.rb
class EventTypesController < ApplicationController
  include Navigable
  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_present
  before_action :set_event_type, only: %i[show edit update destroy]
  before_action :set_policy,     only: %i[show edit update destroy]
  before_action :require_admin, only: %i[new create]

  def index
    @event_types = EventType.order("LOWER(name) ASC")
  end

  def show
  end

  def new
    @event_type = EventType.new
  end

  def create
    @event_type = EventType.new(event_type_params)
    if @event_type.save
      redirect_to @event_type, notice: "Event type created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to event_types_path, alert: "Not authorised." unless @policy.can_update?
  end

  def update
    unless @policy.can_update?
      redirect_to event_types_path, alert: "Not authorised." and return
    end
    if @event_type.update(event_type_params)
      redirect_to @event_type, notice: "Event type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to event_types_path, alert: "Not authorised." and return
    end
    @event_type.destroy
    if @event_type.errors.any?
      redirect_to event_type_path(@event_type),
                  alert: @event_type.errors.full_messages.to_sentence
    else
      redirect_to event_types_path, notice: "Event type deleted."
    end
  end

  private

  def require_admin
    unless current_user&.can_administer?
      redirect_to event_types_path, alert: "Not authorised."
    end
  end

  def resume_session_if_present
    Current.session ||= find_session_by_cookie
  end

  def set_policy
    @policy = Policy.new(current_user, @event_type)
  end

  def set_event_type
    @event_type = EventType.friendly.find(params[:id])
  end

  def event_type_params
    params.require(:event_type).permit(:name, :description, :icon)
  end
end
