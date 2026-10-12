# app/controllers/concerns/return_to.rb

# A `return_to` query param that sends a page's Back button to wherever the
# reader came from (Browse, Filter, My Recipes) instead of a fixed index —
# Design Question-4 in docs/context-prompts/active/Cookbook_App.md. Only a
# relative path on this site is honoured, so the param can't be used as an
# open redirect; anything else falls back.
module ReturnTo
  extend ActiveSupport::Concern

  included do
    helper_method :return_to_or
  end

  private

  def return_to_or(fallback)
    path = params[:return_to].to_s
    safe_return_to?(path) ? path : fallback
  end

  def safe_return_to?(path)
    return false unless path.start_with?("/")
    return false if path.start_with?("//") || path.include?("\\")

    uri = URI.parse(path)
    uri.scheme.nil? && uri.host.nil?
  rescue URI::InvalidURIError
    false
  end
end
