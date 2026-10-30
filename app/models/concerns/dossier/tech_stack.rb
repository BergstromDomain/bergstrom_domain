# app/models/concerns/dossier/tech_stack.rb

# An Assignment's mandatory Tech Stack: system_under_test plus five Skill
# lists. Each list is set as comma-separated text (e.g. test_tools_text =
# "Jira, qTest"), matched to Skills by name or alias; unknown names become new
# Skills in the "Uncategorised" Skill Category. A list must have items or its
# *_na flag, never both.
module Dossier
  module TechStack
    extend ActiveSupport::Concern

    # stack_slot => the plural used in the *_text / *_na attribute names
    SLOTS = {
      operating_system: :operating_systems,
      methodology:      :methodologies,
      test_tool:        :test_tools,
      other_tool:       :other_tools,
      protocol:         :protocols
    }.freeze

    ALL_NA = SLOTS.values.to_h { |plural| [ :"#{plural}_na", true ] }.merge(system_under_test: "N/A").freeze

    UNCATEGORISED = "Uncategorised"

    included do
      has_many :assignment_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :assignment
      has_many :skills, through: :assignment_skills

      normalizes :system_under_test, with: ->(value) { value.strip }

      validates :system_under_test, presence: true
      validate  :tech_stack_lists_are_complete

      before_validation :apply_tech_stack_text
    end

    SLOTS.each do |slot, plural|
      define_method(:"#{plural}_text") do
        tech_stack_text.fetch(slot) { skills_in(slot).map(&:name).join(", ") }
      end

      define_method(:"#{plural}_text=") { |text| tech_stack_text[slot] = text.to_s }
    end

    def skills_in(slot)
      assignment_skills.reject(&:marked_for_destruction?).select { |as| as.stack_slot == slot.to_s }.map(&:skill)
    end

    def tech_stack_blank?
      system_under_test.to_s.strip.casecmp?("N/A") && SLOTS.values.all? { |plural| public_send(:"#{plural}_na") }
    end

    private

    def tech_stack_text
      @tech_stack_text ||= {}
    end

    def apply_tech_stack_text
      new_skills = {}
      tech_stack_text.each do |slot, text|
        names = text.split(",").map(&:strip).compact_blank.uniq(&:downcase)
        wanted = names.map { |name| Dossier::Skill.find_by_name_or_alias(name) || (new_skills[name.downcase] ||= new_skill(name)) }.uniq

        current = assignment_skills.reject(&:marked_for_destruction?).select { |as| as.stack_slot == slot.to_s }
        current.each { |as| as.mark_for_destruction unless wanted.include?(as.skill) }
        wanted.each do |skill|
          assignment_skills.build(skill: skill, stack_slot: slot.to_s) unless current.any? { |as| as.skill == skill }
        end
      end
      tech_stack_text.clear
    end

    def new_skill(name)
      Dossier::Skill.new(name: name, skill_category: Dossier::SkillCategory.find_or_create_by!(name: UNCATEGORISED))
    end

    def tech_stack_lists_are_complete
      SLOTS.each do |slot, plural|
        filled = skills_in(slot).any?
        na = public_send(:"#{plural}_na")
        if na && filled
          errors.add(:"#{plural}_text", "must be empty when N/A is ticked")
        elsif !na && !filled
          errors.add(:"#{plural}_text", "needs at least one item, or tick N/A")
        end
      end
    end
  end
end
