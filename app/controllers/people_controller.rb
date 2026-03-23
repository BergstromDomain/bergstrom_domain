# app/controllers/people_controller.rb

class PeopleController < ApplicationController
  before_action :set_person, only: [ :show, :edit, :update, :destroy ]

  def index
    @people = Person.order(:last_name, :first_name)
  end

  def show; end

  def new
    @person = Person.new
  end

  def edit; end

  def create
    @person = Person.new(person_params)
    if @person.save
      redirect_to @person, notice: "Person was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: "Person was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: "Person was successfully deleted."
  end

  private

  def set_person
    @person = Person.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end

  def person_params
    params.require(:person).permit(
      :first_name, :middle_name, :last_name,
      :description, :thumbnail_image, :full_image
    )
  end
end
