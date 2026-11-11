# db/migrate/20261112090000_create_dossier_contributions.rb

# Contributions: talks, workshops, articles and other community work (see
# Dossier::Contribution), with their Skills.
class CreateDossierContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_contributions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false, default: "talk"
      t.string :title, null: false
      t.references :event, foreign_key: { to_table: :dossier_organisations }
      t.date :start_on
      t.string :start_precision, null: false, default: "month"
      t.date :end_on
      t.string :end_precision, null: false, default: "month"
      t.string :location
      t.string :url
      t.string :presented_as
      t.text :description
      t.references :engagement, foreign_key: { to_table: :dossier_engagements }
      t.string :classification, null: false, default: "restricted"
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :dossier_contributions, :deleted_at

    create_table :dossier_contribution_skills do |t|
      t.references :contribution, null: false, foreign_key: { to_table: :dossier_contributions }
      t.references :skill, null: false, foreign_key: { to_table: :dossier_skills }
      t.timestamps
    end
    add_index :dossier_contribution_skills, %i[contribution_id skill_id], unique: true
  end
end
