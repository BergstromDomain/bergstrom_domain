# db/migrate/YYYYMMDDHHMMSS_add_user_to_events.rb
class AddUserToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :user, null: true, foreign_key: true
  end
end
