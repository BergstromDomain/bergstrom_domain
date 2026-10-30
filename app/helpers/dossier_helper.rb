# app/helpers/dossier_helper.rb
module DossierHelper
  # The page for a Timeline bench or gap period (a Dossier::Timeline::Period).
  def period_path_for(period)
    dossier_period_path(from: period.from.iso8601, to: period.to.iso8601)
  end
end
