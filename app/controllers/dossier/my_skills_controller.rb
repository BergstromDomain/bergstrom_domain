# app/controllers/dossier/my_skills_controller.rb

# My Career › Skills: every Skill the signed-in user has used, grouped by
# Skill Category, with their years of experience.
class Dossier::MySkillsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  def index
    experiences = Dossier::ExperienceCalculator.new(current_user).skills
    ActiveRecord::Associations::Preloader.new(records: experiences.map(&:skill), associations: :skill_category).call
    @groups = experiences.group_by { |experience| experience.skill.skill_category }
                         .sort_by { |category, _| category.name.downcase }
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
