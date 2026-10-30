# app/models/dossier/skill_category.rb
class Dossier::SkillCategory < ApplicationRecord
  include Dossier::NamedReferenceData

  has_many :skills, dependent: :restrict_with_error
end
