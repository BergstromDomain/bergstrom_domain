# app/controllers/people_controller.rb
class PeopleController < ApplicationController
  include Navigable

  allow_unauthenticated_access only: %i[index show]
  before_action :resume_session_if_available, only: %i[index show]
  before_action :set_person,  only: %i[show edit update destroy]
  before_action :set_policy,  only: %i[index new create edit update destroy]

  def index
    @people = if !authenticated?
      Person.visible_to_visitors
    elsif current_user.can_administer?
      Person.visible_to_admins
    else
      Person.visible_to_users(current_user)
    end.order("LOWER(last_name), LOWER(first_name)")
       .includes(:image_attachment, :image_blob)
  end

  def show
    @policy = Policy.new(current_user, @person)
    unless @policy.can_read?
      redirect_to people_path, alert: "You do not have permission to view that person."
    end
  end

  def new
    @person = Person.new
  end

  def create
    unless @policy.can_create?
      redirect_to people_path, alert: "You do not have permission to create people."
      return
    end

    @person = Person.new(person_params)
    @person.user = current_user
    if @person.save
      redirect_to @person, notice: "Person was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @policy.can_update?
      redirect_to @person, alert: "You do not have permission to modify that person."
    end
  end

  def update
    unless @policy.can_update?
      redirect_to @person, alert: "You do not have permission to modify that person."
      return
    end

    if @person.update(person_params)
      redirect_to @person, notice: "Person was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @policy.can_delete?
      redirect_to @person, alert: "You do not have permission to delete that person."
      return
    end

    @person.destroy
    redirect_to people_path, notice: "Person was successfully deleted."
  end

  private

  def set_person
    @person = Person.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def set_policy
    resource = defined?(@person) && @person ? @person : :event_tracker
    @policy  = Policy.new(current_user, resource)
  end

  def resume_session_if_available
    resume_session
  end

  def person_params
    params.require(:person).permit(
      :first_name,
      :middle_name,
      :last_name,
      :description,
      :classification,
      :image
    )
  end
end
