# Dossier Block 1d — mandatory Tech Stack per Assignment: System Under Test
# plus five Skill lists (AssignmentSkill.stack_slot), each filled or N/A.
class AddTechStackToDossierAssignments < ActiveRecord::Migration[8.1]
  def change
    change_table :dossier_assignments, bulk: true do |t|
      t.text    :system_under_test,    null: false, default: "N/A"
      t.boolean :operating_systems_na, null: false, default: false
      t.boolean :methodologies_na,     null: false, default: false
      t.boolean :test_tools_na,        null: false, default: false
      t.boolean :other_tools_na,       null: false, default: false
      t.boolean :protocols_na,         null: false, default: false
    end
    # The default only fills existing rows; new Assignments must name it.
    change_column_default :dossier_assignments, :system_under_test, from: "N/A", to: nil

    create_table :dossier_assignment_skills do |t|
      t.references :assignment, null: false, foreign_key: { to_table: :dossier_assignments }
      t.references :skill,      null: false, foreign_key: { to_table: :dossier_skills }
      t.string     :stack_slot
      t.boolean    :primary,    null: false, default: false
      t.timestamps
    end
    add_index :dossier_assignment_skills, %i[assignment_id skill_id stack_slot], unique: true,
              name: "index_dossier_assignment_skills_uniqueness"
  end
end
