# app/models/concerns/dossier/skill_tags.rb

# Skills typed as comma-separated text (skills_text), matched by name or
# alias; unknown names become new Skills in "Uncategorised". The including
# model has a has_many of join rows (each with a skill) and names it with
# skill_tags :association.
module Dossier
  module SkillTags
    extend ActiveSupport::Concern

    included do
      class_attribute :skill_links_association
      before_validation :apply_skills_text
    end

    class_methods do
      def skill_tags(association)
        self.skill_links_association = association
      end
    end

    def skills_text
      @skills_text || current_skills.map(&:name).join(", ")
    end

    def skills_text=(text)
      @skills_text = text.to_s
    end

    def current_skills
      skill_links.reject(&:marked_for_destruction?).map(&:skill)
    end

    private

    def skill_links = public_send(skill_links_association)

    def apply_skills_text
      return if @skills_text.nil?

      wanted = Dossier::SkillNames.new.skills(@skills_text)

      current = skill_links.reject(&:marked_for_destruction?)
      current.each { |link| link.mark_for_destruction unless wanted.include?(link.skill) }
      wanted.each { |skill| skill_links.build(skill: skill) unless current.any? { |link| link.skill == skill } }
      @skills_text = nil
    end
  end
end
