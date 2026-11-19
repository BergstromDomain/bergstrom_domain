# db/migrate/20261119120000_add_timeline_hide_gaps_to_user_app_settings.rb

# Dossier: the Timeline's Hide Gaps tick (gaps and bench rows), kept per user.
class AddTimelineHideGapsToUserAppSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_app_settings, :timeline_hide_gaps, :boolean, null: false, default: false
  end
end
