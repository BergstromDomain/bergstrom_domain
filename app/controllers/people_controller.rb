class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update]

  def index
    @people = Person.alphabetical
  end

  def show
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: "Person was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_person
    @person = Person.find_by!(slug: params[:id])
  end

  def person_params
    params.require(:person).permit(
      :firstname,
      :middlename,
      :lastname,
      :description,
      :full_image
    )
  end
end
