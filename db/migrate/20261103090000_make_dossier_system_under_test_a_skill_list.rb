# db/migrate/20261103090000_make_dossier_system_under_test_a_skill_list.rb

# System Under Test becomes a sixth Tech Stack Skill list (stack_slot
# "system_under_test", with its own N/A flag). Existing text is split on
# commas into Skills, matched by name or alias, unknown ones in Uncategorised.
class MakeDossierSystemUnderTestASkillList < ActiveRecord::Migration[8.1]
  def up
    add_column :dossier_assignments, :systems_under_test_na, :boolean, null: false, default: false

    select_rows("SELECT id, system_under_test FROM dossier_assignments").each do |id, text|
      names = text.to_s.split(",").map(&:strip).compact_blank.uniq(&:downcase)
      if names.empty? || names.map(&:downcase) == [ "n/a" ]
        execute "UPDATE dossier_assignments SET systems_under_test_na = TRUE WHERE id = #{Integer(id)}"
        next
      end

      names.each do |name|
        skill = Dossier::Skill.find_by_name_or_alias(name) || Dossier::Skill.new_uncategorised(name).tap(&:save!)
        Dossier::AssignmentSkill.find_or_create_by!(assignment_id: id, skill: skill, stack_slot: "system_under_test")
      end
    end

    remove_column :dossier_assignments, :system_under_test
  end

  def down
    add_column :dossier_assignments, :system_under_test, :text

    select_rows("SELECT id, systems_under_test_na FROM dossier_assignments").each do |id, na|
      names = Dossier::AssignmentSkill.where(assignment_id: id, stack_slot: "system_under_test")
                                      .order(:id).includes(:skill).map { |as| as.skill.name }
      text = na || names.empty? ? "N/A" : names.join(", ")
      execute "UPDATE dossier_assignments SET system_under_test = #{connection.quote(text)} WHERE id = #{Integer(id)}"
    end
    execute "DELETE FROM dossier_assignment_skills WHERE stack_slot = 'system_under_test'"

    change_column_null :dossier_assignments, :system_under_test, false
    remove_column :dossier_assignments, :systems_under_test_na
  end
end
