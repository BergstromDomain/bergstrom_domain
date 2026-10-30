# app/models/dossier/assignment_skill.rb

# A Skill used on an Assignment. stack_slot places it in one of the Tech
# Stack's lists (nil = used, but not part of the Tech Stack). The slot lives
# here, not on the Skill, since Excel can be a test tool on one Assignment
# and another tool elsewhere.
class Dossier::AssignmentSkill < ApplicationRecord
  belongs_to :assignment
  belongs_to :skill

  validates :stack_slot, inclusion: { in: Dossier::TechStack::SLOTS.keys.map(&:to_s) }, allow_nil: true
end
