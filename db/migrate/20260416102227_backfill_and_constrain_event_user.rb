# db/migrate/20260416102227_backfill_and_constrain_event_user.rb
class BackfillAndConstrainEventUser < ActiveRecord::Migration[8.1]
  def up
    admin_id = execute("SELECT id FROM users ORDER BY id ASC LIMIT 1").first&.fetch("id")
    execute("UPDATE events SET user_id = #{admin_id} WHERE user_id IS NULL") if admin_id
    change_column_null :events, :user_id, false
  end

  def down
    change_column_null :events, :user_id, true
  end
end
