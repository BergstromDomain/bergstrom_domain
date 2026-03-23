# db/migrate/YYYYMMDDHHMMSS_create_events.rb
class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string  :title,           null: false
      t.text    :description
      t.integer :day,             null: false
      t.integer :month,           null: false
      t.integer :year
      t.string  :image
      t.string  :thumbnail_image
      t.string  :slug

      t.timestamps
    end

    add_index :events, :title, unique: true
    add_index :events, :slug,  unique: true
    add_index :events, [ :month, :day ],         name: "index_events_on_month_day"
    add_index :events, [ :year, :month, :day ],  name: "index_events_on_year_month_day"
  end
end
