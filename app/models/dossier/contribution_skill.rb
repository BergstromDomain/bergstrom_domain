# app/models/dossier/contribution_skill.rb

# A Skill a Contribution (a talk, an article…) is tagged with.
class Dossier::ContributionSkill < ApplicationRecord
  belongs_to :contribution
  belongs_to :skill
end
