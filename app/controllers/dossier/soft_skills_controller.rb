# app/controllers/dossier/soft_skills_controller.rb

# My Career › Soft Skills: each Soft Skill with the signed-in user's examples
# of it, the Achievements and Contributions tagged with it, for applications
# and interviews that ask for one.
class Dossier::SoftSkillsController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  def index
    @entries = Dossier::SoftSkillExamples.new(current_user).entries
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
