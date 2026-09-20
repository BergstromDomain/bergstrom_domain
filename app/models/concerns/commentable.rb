# app/models/concerns/commentable.rb
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
  end
end
