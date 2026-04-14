# app/controllers/event_types_controller.rb
class EventTypesController < ApplicationController
  before_action :set_event_type, only: %i[show edit update destroy]

  def index
    @event_types = EventType.order(:name)
  end

  def show; end

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

  def edit; end

  def update
    if @event_type.update(event_type_params)
      redirect_to @event_type, notice: "Event type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event_type.destroy
    if @event_type.errors.any?
      redirect_to event_type_path(@event_type),
                  alert: @event_type.errors.full_messages.to_sentence
    else
      redirect_to event_types_path, notice: "Event type deleted."
    end
  end

  private

  def set_event_type
    @event_type = EventType.friendly.find(params[:id])
  end

  def event_type_params
    params.require(:event_type).permit(:name, :description, :icon)
  end
end
