# app/services/dossier/soft_skill_examples.rb

# My Career › Soft Skills: every Soft Skill, A–Z, with the user's examples of
# it: their Achievements tagged with it (most important first, on kept
# Engagements and Assignments) and their kept Contributions (newest first).
class Dossier::SoftSkillExamples
  Entry = Data.define(:skill, :achievements, :contributions) do
    def size = achievements.size + contributions.size
  end

  def initialize(user)
    @user = user
  end

  def entries
    @entries ||= Dossier::Skill.soft.to_a.map do |skill|
      Entry.new(skill: skill, achievements: achievements.fetch(skill.id, []), contributions: contributions.fetch(skill.id, []))
    end
  end

  private

  # skill id => Achievements
  def achievements
    @achievements ||= begin
      experiences = Dossier::ExperienceCalculator.new(@user).soft_skills
      shown = experiences.flat_map(&:achievements).uniq
      ActiveRecord::Associations::Preloader.new(records: shown, associations: { assignment: %i[client role] }).call if shown.any?
      experiences.to_h do |experience|
        [ experience.skill.id, experience.achievements.sort_by { |a| [ -a.importance, a.assignment.start_on ] } ]
      end
    end
  end

  # skill id => Contributions
  def contributions
    @contributions ||= @user.dossier_contributions.kept.newest_first.includes(:event, :contribution_skills).to_a
                            .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |contribution, found|
      contribution.contribution_skills.each { |link| found[link.skill_id] << contribution }
    end
  end
end
