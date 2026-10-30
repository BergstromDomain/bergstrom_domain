# Dossier Block 1c — Engagement (who employed or contracted you) › Assignment
# (where the work was done). Dates carry a day/month precision flag (Q-D18);
# month-precision dates are stored as the 1st of the month.
class CreateDossierEngagementsAndAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_engagements do |t|
      t.references :user,            null: false, foreign_key: true
      t.references :employer,        null: false, foreign_key: { to_table: :dossier_organisations }
      t.references :employment_type, null: false, foreign_key: { to_table: :dossier_employment_types }
      t.string     :position_title,  null: false
      t.date       :start_on,        null: false
      t.string     :start_precision, null: false, default: "month"
      t.date       :end_on
      t.string     :end_precision,   null: false, default: "month"
      t.text       :summary
      t.string     :classification,  null: false, default: "restricted"
      t.datetime   :deleted_at
      t.timestamps
    end
    add_index :dossier_engagements, :deleted_at

    create_table :dossier_assignments do |t|
      t.references :engagement,      null: false, foreign_key: { to_table: :dossier_engagements }
      t.references :user,            null: false, foreign_key: true
      t.references :client,          null: false, foreign_key: { to_table: :dossier_organisations }
      t.references :role,            foreign_key: { to_table: :dossier_roles }
      t.references :location,        foreign_key: { to_table: :dossier_locations }
      t.boolean    :remote,          null: false, default: false
      t.date       :start_on,        null: false
      t.string     :start_precision, null: false, default: "month"
      t.date       :end_on
      t.string     :end_precision,   null: false, default: "month"
      t.text       :summary
      t.string     :classification,  null: false, default: "restricted"
      t.integer    :position
      t.timestamps
    end
  end
end
