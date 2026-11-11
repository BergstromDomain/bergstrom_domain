# db/migrate/20261111120000_create_dossier_engagement_colleagues.rb

# An Engagement's Colleagues: People you worked with during it, though not on
# an Assignment you shared (see Dossier::EngagementColleague).
class CreateDossierEngagementColleagues < ActiveRecord::Migration[8.1]
  def change
    create_table :dossier_engagement_colleagues do |t|
      t.references :engagement, null: false, foreign_key: { to_table: :dossier_engagements }
      t.references :person, null: false, foreign_key: true
      t.string :position
      t.text :comment
      t.timestamps
    end
    add_index :dossier_engagement_colleagues, %i[engagement_id person_id], unique: true
  end
end
