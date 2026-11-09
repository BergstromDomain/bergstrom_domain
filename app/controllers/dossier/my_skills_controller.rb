# app/controllers/dossier/my_skills_controller.rb

# My Career › Skills: every Skill the signed-in user has used, grouped by
# Skill Category, with their years of experience.
class Dossier::MySkillsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  # [[top-level category, [[sub-category or nil, experiences], …]], …]: top
  # level A–Z, its own Skills first, then each sub-category's A–Z; most years
  # first within each.
  def index
    experiences = Dossier::ExperienceCalculator.new(current_user).skills
    ActiveRecord::Associations::Preloader.new(records: experiences.map(&:skill), associations: { skill_category: :parent }).call
    @groups = experiences.group_by { |experience| experience.skill.skill_category.parent || experience.skill.skill_category }
                         .sort_by { |category, _| category.name.downcase }
                         .map { |category, list| [ category, subgroups(category, list) ] }
  end

  private

  def subgroups(category, experiences)
    experiences.group_by { |experience| experience.skill.skill_category }
               .sort_by { |subcategory, _| subcategory == category ? "" : subcategory.name.downcase }
               .map { |subcategory, list| [ (subcategory unless subcategory == category), list ] }
  end

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
