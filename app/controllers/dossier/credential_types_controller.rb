# app/controllers/dossier/credential_types_controller.rb
class Dossier::CredentialTypesController < Dossier::ReferenceDataController
  private

  def model_class          = Dossier::CredentialType
  def permitted_attributes = %i[name description position training]
  def subtitle             = "Kinds of Credential, in the order My Career › Credentials groups them. Training types also show in the Training panels."
  def index_groups         = [ [ nil, model_class.in_order ] ]

  def details(record)
    [ [ "Sort Order", record.position.to_s, "position" ],
      [ "Training", record.training? ? "Yes" : "No", "training" ] ]
  end
end
