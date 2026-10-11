# spec/support/bullet_helpers.rb

# Turns Bullet on (raising) for just the block, so a spec can assert code has
# no N+1 queries without enabling Bullet for the whole suite. A request made
# inside the block is checked by Bullet's own Rack middleware; plain code is
# checked when the block ends. Either way a flagged query raises
# Bullet::Notification::UnoptimizedQueryError.
module BulletHelpers
  def without_n_plus_one_queries
    Bullet.enable = true
    Bullet.raise  = true
    # Same reviewed false positive as config/environments/development.rb.
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob
    Bullet.start_request
    yield
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
  ensure
    Bullet.end_request
    Bullet.raise  = false
    Bullet.enable = false
  end
end

RSpec.configure do |config|
  config.include BulletHelpers, type: :request
end
