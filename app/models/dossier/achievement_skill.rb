# app/models/dossier/achievement_skill.rb

# A Skill an Achievement is tagged with.
class Dossier::AchievementSkill < ApplicationRecord
  belongs_to :achievement
  belongs_to :skill
end
