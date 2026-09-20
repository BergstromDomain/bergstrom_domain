# app/controllers/concerns/blog_post_filterable.rb

# Shared Basic/SQL filtering orchestration for any controller that needs "the
# posts the current viewer can see, narrowed by the Filter Blog Posts params"
# — originally BlogPostsController#filter alone, now also BlogExportsController
# (its "Download Blog Posts" page reuses the exact same filter UI/engine so a
# download always matches what's on screen).
module BlogPostFilterable
  extend ActiveSupport::Concern

  private

  def compute_filtered_blog_posts
    posts = visible_blog_posts_scope.includes(:user, :blog_category, :likes).to_a

    @mode  = params[:mode] == "sql" ? "sql" : "basic"
    @query = params[:query].to_s
    @filter_error = nil
    @posts = posts

    begin
      ast =
        if @mode == "sql"
          @query.presence && Jql::Parser.parse(@query)
        else
          BlogPostFilter.basic_ast(**basic_filter_params)
        end

      if ast
        BlogPostFilter::EVALUATOR.validate!(ast)
        @posts = posts.select { |post| BlogPostFilter::EVALUATOR.matches?(ast, BlogPostFilter.attributes_for(post)) }
      end
    rescue Jql::ParseError => e
      @filter_error = e.message
      @posts = []
    end

    set_filter_options(posts)
  end

  # Mirrors PeopleController#index's exact three-way visibility split
  # (app/controllers/people_controller.rb) — BlogPost already has all three
  # scopes from Foundation.
  def visible_blog_posts_scope
    if !authenticated?
      BlogPost.visible_to_visitors
    elsif current_user.can_administer?
      BlogPost.visible_to_admins
    else
      BlogPost.visible_to_users(current_user)
    end
  end

  def basic_filter_params
    category = params[:category_id].presence && safe_find_category(params[:category_id])
    author   = params[:author_id].presence && safe_find_author(params[:author_id])

    {
      category:      category&.name,
      subject:       params[:subject].presence,
      topic:         params[:topic].presence,
      author_name:   author && "#{author.first_name} #{author.last_name}",
      created_range: created_range_for(params[:created]),
      published:     published_filter_for(params[:published])
    }
  end

  def published_filter_for(value)
    case value
    when "published" then "true"
    when "draft"      then "false"
    end
  end

  def safe_find_category(id)
    BlogCategory.friendly.find(id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def safe_find_author(id)
    User.find(id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def created_range_for(value)
    case value
    when "today"      then Date.current..Date.current
    when "this_week"  then Date.current.beginning_of_week..Date.current
    when "this_month" then Date.current.beginning_of_month..Date.current
    when "this_year"  then Date.current.beginning_of_year..Date.current
    end
  end

  def set_filter_options(posts)
    @category_options = BlogCategory.where(id: posts.filter_map(&:blog_category_id)).order("LOWER(name) ASC")
    @subject_options   = posts.map(&:subject).compact_blank.uniq.sort
    @topic_options     = posts.map(&:topic).compact_blank.uniq.sort
    @author_options    = posts.map(&:user).uniq.sort_by { |user| [ user.last_name.downcase, user.first_name.downcase ] }
  end
end
