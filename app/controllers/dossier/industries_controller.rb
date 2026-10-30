# app/controllers/dossier/industries_controller.rb
class Dossier::IndustriesController < Dossier::ReferenceDataController
  private

  def model_class = Dossier::Industry
  def subtitle    = "Each Organisation belongs to one Industry, used for experience by industry."
end
