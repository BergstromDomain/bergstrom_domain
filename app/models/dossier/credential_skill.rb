# app/models/dossier/credential_skill.rb

# A Skill a Credential (a course) is tagged with.
class Dossier::CredentialSkill < ApplicationRecord
  belongs_to :credential
  belongs_to :skill
end
