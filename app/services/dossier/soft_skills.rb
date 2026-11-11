# app/services/dossier/soft_skills.rb

# The "Soft Skills" category and its Skills, merged from a job ad's
# soft-skill criteria; the ad's own wording is each Skill's aliases, so typing
# it links the Skill. Safe to run again: it adds what's missing and leaves
# what's there, edits included. A Skill already in another category under the
# same name stays where it is. The category was first called "Professional
# Skills": one by that name is renamed.
class Dossier::SoftSkills
  CATEGORY = "Soft Skills"
  EARLIER_NAME = "Professional Skills"

  # name => [description, aliases]
  SKILLS = {
    "Working with Technical Experts" => [
      "Working with technical teams to deliver large implementations, such as Salesforce, MuleSoft, " \
      "other CRM or digital projects.", [ "Ability to work with Technical Experts" ]
    ],
    "Strategic Thinking" => [
      "Strategic thinking and decision-making.", [ "Excellent Strategic Thinking", "Decision Making" ]
    ],
    "Stakeholder Management" => [
      "Managing relationships with key stakeholders.", [ "Stakeholder Relationships" ]
    ],
    "Communication & Presentation" => [
      "Communicating clearly in writing and in person, presenting, and contributing to team discussions and decisions.",
      [ "Communication and Presentation Skills", "Communication", "Collaboration and Communication" ]
    ],
    "Analytical Problem Solving" => [
      "Analysing problems and solving them.", [ "Analytical and Problem-solving Skills", "Problem Solving" ]
    ],
    "Leadership" => [
      "Leading people and teams.", [ "Leadership Skills" ]
    ],
    "Adaptability" => [
      "Responding to changing requirements and priorities, and working flexibly across tasks, roles and projects.",
      [ "Flexibility and Adaptability", "Flexibility" ]
    ],
    "Cross-Functional Collaboration" => [
      "Collaborating with, and supporting, team members from other disciplines to reach the project's goals.",
      [ "Cross-Functional Support", "Collaboration" ]
    ],
    "Knowledge Sharing" => [
      "Sharing knowledge and skills, taking part in learning, and improving the team continuously.",
      [ "Knowledge Sharing and Learning", "Mentoring" ]
    ]
  }.freeze

  # The category, with every Skill added that wasn't there.
  def self.seed!
    Dossier::SkillCategory.transaction do
      category = find_category(CATEGORY) || find_category(EARLIER_NAME) || Dossier::SkillCategory.new
      category.update!(name: category.name&.casecmp?(CATEGORY) ? category.name : CATEGORY, soft: true)
      SKILLS.each do |name, (description, aliases)|
        next if Dossier::Skill.find_by_name_or_alias(name)

        free = aliases.reject { |text| Dossier::Skill.find_by_name_or_alias(text) }
        category.skills.create!(name: name, description: description, aliases: free)
      end
      category
    end
  end

  def self.find_category(name)
    Dossier::SkillCategory.top_level.find_by("LOWER(name) = ?", name.downcase)
  end
  private_class_method :find_category
end
