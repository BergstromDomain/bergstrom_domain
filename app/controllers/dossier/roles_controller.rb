# app/controllers/dossier/roles_controller.rb
class Dossier::RolesController < Dossier::ReferenceDataController
  private

  def model_class = Dossier::Role
  def subtitle    = "What you did for a client on an Assignment, e.g. Test Manager."
end
