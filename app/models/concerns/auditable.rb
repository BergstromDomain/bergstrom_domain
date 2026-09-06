# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    belongs_to :updater, class_name: "User", optional: true
  end
end
