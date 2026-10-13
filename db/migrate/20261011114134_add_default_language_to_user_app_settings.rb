class AddDefaultLanguageToUserAppSettings < ActiveRecord::Migration[8.1]
  def change
    # Cookbook only. Deleting a Language quietly clears anyone's default.
    add_reference :user_app_settings, :default_language,
                  foreign_key: { to_table: :languages, on_delete: :nullify }
  end
end
