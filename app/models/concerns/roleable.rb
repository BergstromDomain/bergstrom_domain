# app/models/concerns/roleable.rb
module Roleable
  extend ActiveSupport::Concern

  included do
    enum :role, {
      app_user:        "app_user",
      content_creator: "content_creator",
      admin:           "admin",
      system_admin:    "system_admin"
    }, validate: true

    validates :role, presence: true
  end

  def can_administer?
    admin? || system_admin?
  end

  def can_create_content?
    content_creator? || admin? || system_admin?
  end
end
