class PeopleController < ApplicationController
  def index
    @people = Person.alphabetical
  end

  def show
    @person = Person.find_by!(slug: params[:id])
  end
end
