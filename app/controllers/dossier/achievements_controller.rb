# app/controllers/dossier/achievements_controller.rb

# Achievements under the signed-in user's Assignments. New takes an optional
# assignment_id to preselect the Assignment (from its "Add Achievement"
# button). Creating returns to the Assignment, ready for the next bullet.
# Deleting is soft.
class Dossier::AchievementsController < ApplicationController
  include Navigable
  before_action :require_dossier_access, only: %i[new create]
  before_action :set_achievement, only: %i[show edit update destroy move]

  helper_method :assignment_choices

  def show
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @achievement).can_read?
  end

  def new
    @achievement = Dossier::Achievement.new(assignment: assignment_choices.find_by(id: params[:assignment_id]))
  end

  def create
    @achievement = Dossier::Achievement.new(achievement_params)
    @achievement.assignment = assignment_choices.find_by(id: params.dig(:dossier_achievement, :assignment_id))
    if @achievement.save
      toast_created(@achievement)
      redirect_to @achievement.assignment
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dossier_engagements_path, alert: "Not authorised." unless Policy.new(current_user, @achievement).can_update?
  end

  def update
    unless Policy.new(current_user, @achievement).can_update?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    previous_label = @achievement.to_toast_label
    if @achievement.update(achievement_params)
      toast_updated(@achievement, previous_label: previous_label)
      redirect_to @achievement
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless Policy.new(current_user, @achievement).can_delete?
      redirect_to dossier_engagements_path, alert: "Not authorised." and return
    end
    @achievement.soft_delete!
    toast_deleted(@achievement)
    redirect_to @achievement.assignment
  end

  # Up/Down on the Assignment page.
  def move
    if Policy.new(current_user, @achievement).can_update?
      @achievement.move!(params[:direction])
      redirect_to dossier_assignment_path(@achievement.assignment, anchor: "achievements")
    else
      redirect_to dossier_engagements_path, alert: "Not authorised."
    end
  end

  private

  def assignment_choices
    Dossier::Assignment.joins(:engagement).merge(current_user.dossier_engagements.kept)
                       .includes(:client, engagement: :employer).order("dossier_engagements.start_on DESC", start_on: :desc)
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end

  def set_achievement
    @achievement = Dossier::Achievement.includes(achievement_skills: :skill).find(params[:id])
  end

  def achievement_params
    params.require(:dossier_achievement).permit(:text, :impact, :importance, :skills_text)
  end
end
