# app/controllers/concerns/browsable.rb

# Controller side of the shared Browse drill-down (see BrowseTree and
# app/views/shared/browse/). Any app can include this, describe its levels,
# and render the shared partials with its own card partial.
module Browsable
  extend ActiveSupport::Concern

  included do
    helper_method :browse_path_for
  end

  private

  # Builds @browse_tree from the request params. Redirects to the Browse root
  # and returns false when the URL names a first-level record that doesn't
  # exist (e.g. a deleted category or a stale bookmark).
  def load_browse_tree(scope:, levels:, root_label:, path_helper:)
    @browse_path_helper = path_helper
    @browse_root_label  = root_label
    @browse_tree = BrowseTree.new(scope: scope, levels: levels,
      params: params.permit(*levels.map(&:key)).to_h)

    return true unless @browse_tree.invalid?

    redirect_to browse_path_for
    false
  end

  def browse_path_for(node_params = {})
    send(@browse_path_helper, node_params)
  end
end
