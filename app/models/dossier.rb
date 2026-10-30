# app/models/dossier.rb

# Namespace for the Dossier app's models (tables prefixed dossier_), so generic
# names like Role, Location or Skill never collide with core or other apps.
module Dossier
  def self.table_name_prefix
    "dossier_"
  end
end
