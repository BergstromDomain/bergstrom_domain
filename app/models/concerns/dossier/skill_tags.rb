# app/models/concerns/dossier/skill_tags.rb

# Skills typed as comma-separated text (skills_text), matched by name or
# alias; unknown names become new Skills in "Uncategorised". The including
# model has a has_many of join rows (each with a skill) and names it with
# skill_tags :association.
#
# With soft_boxes: true (Achievements, Contributions), Soft Skills are ticked
# instead (soft_skill_ids) and skills_text holds only the technical ones. A
# Soft Skill typed in the text is kept too; leaving either one unset keeps
# what it held.
module Dossier
  module SkillTags
    extend ActiveSupport::Concern

    included do
      class_attribute :skill_links_association
      class_attribute :soft_skill_boxes, default: false
      before_validation :apply_skills_text
    end

    class_methods do
      def skill_tags(association, soft_boxes: false)
        self.skill_links_association = association
        self.soft_skill_boxes = soft_boxes
      end
    end

    def skills_text
      @skills_text || typed_skills.map(&:name).join(", ")
    end

    def skills_text=(text)
      @skills_text = text.to_s
    end

    def soft_skill_ids
      @soft_skill_ids || soft_skills.map(&:id)
    end

    def soft_skill_ids=(ids)
      @soft_skill_ids = Array(ids).compact_blank.map(&:to_i)
    end

    def current_skills
      skill_links.reject(&:marked_for_destruction?).map(&:skill)
    end

    def soft_skills
      soft = Dossier::SkillCategory.soft_ids
      current_skills.select { |skill| soft.include?(skill.skill_category_id) }
    end

    def technical_skills = current_skills - soft_skills

    private

    def skill_links = public_send(skill_links_association)

    def typed_skills = soft_skill_boxes ? technical_skills : current_skills

    def ticked_skills
      return (soft_skill_boxes ? soft_skills : []) if @soft_skill_ids.nil?

      Dossier::Skill.where(id: @soft_skill_ids, skill_category_id: Dossier::SkillCategory.soft_ids).to_a
    end

    def apply_skills_text
      return if @skills_text.nil? && @soft_skill_ids.nil?

      typed = @skills_text.nil? ? typed_skills : Dossier::SkillNames.new.skills(@skills_text)
      wanted = typed + ticked_skills.reject { |skill| typed.include?(skill) }

      current = skill_links.reject(&:marked_for_destruction?)
      current.each { |link| link.mark_for_destruction unless wanted.include?(link.skill) }
      wanted.each { |skill| skill_links.build(skill: skill) unless current.any? { |link| link.skill == skill } }
      @skills_text = @soft_skill_ids = nil
    end
  end
end
