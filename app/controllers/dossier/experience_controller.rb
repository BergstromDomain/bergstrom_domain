# app/controllers/dossier/experience_controller.rb

# My Career › Experience: the signed-in user's career totals and years per
# Employer, Client, Industry, Role and Employment Type.
class Dossier::ExperienceController < ApplicationController
  include Navigable
  before_action :require_dossier_access

  # [testid, heading, slice] in page order.
  SECTIONS = [
    [ "employers",        "Employers",        :employer ],
    [ "clients",          "Clients",          :client ],
    [ "industries",       "Industries",       :industry ],
    [ "roles",            "Roles",            :role ],
    [ "employment-types", "Employment Types", :employment_type ]
  ].freeze

  def index
    @calculator = Dossier::ExperienceCalculator.new(current_user)
  end

  private

  def require_dossier_access
    redirect_to dossier_path, alert: "Not authorised." unless Policy.new(current_user, :dossier).can_create?
  end
end
