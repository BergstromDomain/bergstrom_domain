# db/migrate/20261119100000_add_career_break_to_dossier_employment_types.rb

# A career break type (time off, looking for work): its Engagements need no
# Employer, and count towards no experience.
class AddCareerBreakToDossierEmploymentTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :dossier_employment_types, :career_break, :boolean, default: false, null: false
    change_column_null :dossier_engagements, :employer_id, true
  end
end
