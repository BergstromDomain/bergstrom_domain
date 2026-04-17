class CreateAppPermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :app_name
      t.boolean :can_create
      t.boolean :can_update
      t.boolean :can_delete

      t.timestamps
    end
  end
end
