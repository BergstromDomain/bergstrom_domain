# app/models/concerns/dossier/tech_stack.rb

# An Assignment's mandatory Tech Stack: six Skill lists, System Under Test
# first. Each list is set as comma-separated text (e.g. test_tools_text =
# "Jira, qTest"), matched to Skills by Dossier::SkillNames, so "Windows (XP,
# Vista)" means those versions of Windows; unknown names become new Skills in
# the "Uncategorised" Skill Category. A list must have items or its
# *_na flag, never both.
#
# The Assignment form sets the System Under Test as above, and the rest as a
# field per top-level Skill Category (category_skills_text): each Skill goes
# in the list its category belongs to (CATEGORY_SLOTS, else Other Tools), or
# stays in its list if it's already there, and lists left empty become N/A.
module Dossier
  module TechStack
    extend ActiveSupport::Concern

    # stack_slot => the plural used in the *_text / *_na attribute names
    SLOTS = {
      system_under_test: :systems_under_test,
      operating_system:  :operating_systems,
      methodology:      :methodologies,
      test_tool:        :test_tools,
      other_tool:       :other_tools,
      protocol:         :protocols
    }.freeze

    LABELS = {
      systems_under_test: "System Under Test",
      operating_systems: "Operating Systems",
      methodologies:     "Methodology",
      test_tools:        "Test Tools",
      other_tools:       "Other Tools",
      protocols:         "Protocols"
    }.freeze

    # The list a top-level category's Skills go in; any other is Other Tools.
    CATEGORY_SLOTS = {
      "Testing"                        => :test_tool,
      "Test & Measurement Instruments" => :test_tool,
      "Methods & Processes"            => :methodology,
      "Operating Systems"              => :operating_system,
      "Protocols & Standards"          => :protocol
    }.freeze

    # The form field for Skills in a category without a position (Uncategorised).
    OTHER = "other"

    ALL_NA = SLOTS.values.to_h { |plural| [ :"#{plural}_na", true ] }.freeze

    UNCATEGORISED = "Uncategorised"

    included do
      has_many :assignment_skills, -> { order(:id) }, dependent: :destroy, autosave: true, inverse_of: :assignment
      has_many :skills, through: :assignment_skills

      validate :tech_stack_lists_are_complete

      before_validation :apply_tech_stack_text
      before_validation :apply_category_skills_text
    end

    # The form's category fields: top-level categories with a position, in order.
    def self.form_categories
      Dossier::SkillCategory.top_level.where.not(position: nil).order(:position, Arel.sql("LOWER(name)"))
    end

    def self.top_category(skill)
      category = skill.family_root.skill_category
      category.parent || category
    end

    def self.slot_for(skill) = CATEGORY_SLOTS.fetch(top_category(skill).name, :other_tool)

    # The form field a Skill shows in: its top category's id, or OTHER.
    def self.form_key(skill)
      top = top_category(skill)
      top.position ? top.id.to_s : OTHER
    end

    class_methods do
      # "Test Tools needs at least one item…", not "Test tools text needs…"
      def human_attribute_name(attribute, options = {})
        plural = attribute.to_s.delete_suffix("_text").to_sym
        attribute.to_s.end_with?("_text") && LABELS.key?(plural) ? LABELS.fetch(plural) : super
      end
    end

    SLOTS.each do |slot, plural|
      define_method(:"#{plural}_text") do
        tech_stack_text.fetch(slot) { skills_in(slot).map(&:name).join(", ") }
      end

      define_method(:"#{plural}_text=") { |text| tech_stack_text[slot] = text.to_s }
    end

    # { category id or OTHER => "Jira, Windows (XP, 7)" }, from the form.
    def category_skills_text=(texts)
      @category_skills_text = texts.to_h.transform_keys(&:to_s)
    end

    # A form field's Skills in the order entered, a Skill's versions with it:
    # "Linux, Windows (XP, 7)".
    def category_skills_text(key)
      skills = tech_stack_form_skills.select { |skill| Dossier::TechStack.form_key(skill) == key.to_s }
      skills.group_by(&:family_root).flat_map do |root, members|
        versions = members - [ root ]
        [ (root.name if members.include?(root)),
          ("#{root.name} (#{versions.map(&:version_label).join(', ')})" if versions.any?) ].compact
      end.join(", ")
    end

    def skills_in(slot)
      assignment_skills.reject(&:marked_for_destruction?).select { |as| as.stack_slot == slot.to_s }.map(&:skill)
    end

    def tech_stack_blank?
      SLOTS.values.all? { |plural| public_send(:"#{plural}_na") }
    end

    private

    def tech_stack_text
      @tech_stack_text ||= {}
    end

    def links_outside_system_under_test
      assignment_skills.reject { |link| link.marked_for_destruction? || link.stack_slot == "system_under_test" }
    end

    # The Skills the category fields show, with what form_key reads loaded
    # for all of them at once.
    def tech_stack_form_skills
      @tech_stack_form_skills ||= links_outside_system_under_test.map(&:skill).uniq.tap do |skills|
        preloader = ActiveRecord::Associations::Preloader
        preloader.new(records: skills.select(&:persisted?), associations: :parent).call
        roots = skills.map(&:family_root).uniq.select(&:persisted?)
        preloader.new(records: roots, associations: { skill_category: :parent }).call
      end
    end

    def apply_category_skills_text
      return if @category_skills_text.nil?

      names = Dossier::SkillNames.new
      categories = Dossier::SkillCategory.where(id: @category_skills_text.keys - [ OTHER ]).index_by { |c| c.id.to_s }
      wanted = @category_skills_text.flat_map { |key, text| names.skills(text, category: categories[key]) }.uniq
      current = links_outside_system_under_test
      current.each { |link| link.mark_for_destruction unless wanted.include?(link.skill) }
      wanted.each do |skill|
        next if current.any? { |link| link.skill == skill }

        assignment_skills.build(skill: skill, stack_slot: Dossier::TechStack.slot_for(skill).to_s)
      end
      SLOTS.except(:system_under_test).each { |slot, plural| self[:"#{plural}_na"] = skills_in(slot).empty? }
      @category_skills_text = nil
      @tech_stack_form_skills = nil
    end

    def apply_tech_stack_text
      names = Dossier::SkillNames.new
      tech_stack_text.each do |slot, text|
        wanted = names.skills(text)

        current = assignment_skills.reject(&:marked_for_destruction?).select { |as| as.stack_slot == slot.to_s }
        current.each { |as| as.mark_for_destruction unless wanted.include?(as.skill) }
        wanted.each do |skill|
          assignment_skills.build(skill: skill, stack_slot: slot.to_s) unless current.any? { |as| as.skill == skill }
        end
      end
      tech_stack_text.clear
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
