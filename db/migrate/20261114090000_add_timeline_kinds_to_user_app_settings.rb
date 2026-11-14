# db/migrate/20261114090000_add_timeline_kinds_to_user_app_settings.rb

# Dossier: the Timeline's Professional and Personal ticks, kept per user.
class AddTimelineKindsToUserAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_app_settings, :timeline_professional, :boolean, null: false, default: true
    add_column :user_app_settings, :timeline_personal, :boolean, null: false, default: true
  end
end
