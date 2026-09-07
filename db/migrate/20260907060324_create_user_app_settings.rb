class CreateUserAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :user_app_settings do |t|
      t.references :user,                   null: false, foreign_key: true
      t.string     :app_name,                null: false
      t.string     :start_page
      t.string     :default_classification, null: false, default: "restricted"

      t.timestamps
    end

    add_index :user_app_settings, [ :user_id, :app_name ], unique: true
  end
end
