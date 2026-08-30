# app/services/blog_post_filter.rb
class BlogPostFilter
  FIELD_SCHEMA = {
    category:  :string,
    subject:   :string,
    topic:     :string,
    title:     :string,
    author:    :string,
    created:   :date,
    comments:  :integer,
    smiles:    :decimal,
    published: :boolean
  }.freeze

  EVALUATOR = Jql::Evaluator.new(FIELD_SCHEMA)

  def self.attributes_for(post)
    {
      category:  post.blog_category&.name,
      subject:   post.subject,
      topic:     post.topic,
      title:     post.title,
      author:    "#{post.user.first_name} #{post.user.last_name}",
      created:   post.created_at,
      comments:  post.comments_count,
      smiles:    post.like_score,
      published: post.published?
    }
  end

  # Builds an AND of whichever filters are present; returns nil ("no filter,
  # show everything") when every argument is blank. `published` is "true"/
  # "false"/nil (nil means "All", not part of the filter at all).
  def self.basic_ast(category: nil, subject: nil, topic: nil, author_name: nil, created_range: nil, published: nil)
    conditions = []
    conditions << string_comparison(:category, category) if category.present?
    conditions << string_comparison(:subject, subject) if subject.present?
    conditions << string_comparison(:topic, topic) if topic.present?
    conditions << string_comparison(:author, author_name) if author_name.present?
    conditions << string_comparison(:published, published) if published.present?

    if created_range
      conditions << date_comparison(:created, ">=", created_range.first)
      conditions << date_comparison(:created, "<=", created_range.last)
    end

    conditions.reduce { |left, right| Jql::Parser::And.new(left: left, right: right) }
  end

  # Nils sort last regardless of direction.
  def self.sort(posts, column, direction)
    column = column.to_sym
    values = posts.to_h { |post| [ post, attributes_for(post)[column] ] }
    with_nil, without_nil = posts.partition { |post| values[post].nil? }

    sorted = without_nil.sort_by { |post| sort_key(values[post]) }
    sorted.reverse! if direction == "desc"
    sorted + with_nil
  end

  def self.string_comparison(field, value)
    Jql::Parser::Comparison.new(field: field, operator: "=", value: value, value_type: :string)
  end
  private_class_method :string_comparison

  def self.date_comparison(field, operator, date)
    Jql::Parser::Comparison.new(field: field, operator: operator, value: date.iso8601, value_type: :string)
  end
  private_class_method :date_comparison

  def self.sort_key(value)
    value.is_a?(String) ? value.downcase : value
  end
  private_class_method :sort_key
end
