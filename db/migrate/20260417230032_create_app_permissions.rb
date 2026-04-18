class CreateAppPermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :app_permissions do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :app_name,   null: false
      t.boolean    :can_create, null: false, default: false
      t.boolean    :can_update, null: false, default: false
      t.boolean    :can_delete, null: false, default: false

      t.timestamps
    end

    add_index :app_permissions, [ :user_id, :app_name ], unique: true
  end
end
