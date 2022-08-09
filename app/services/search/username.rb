module Search
  class Username
    MAX_RESULTS = 6

    ATTRIBUTES = %i[
      id
      name
      profile_image
      username
    ].freeze

    JOIN_COMMENTS = <<-JOIN_SQL.freeze
    LEFT OUTER JOIN comments on (
      comments.user_id = users.id AND
      comments.commentable_type = '%<commentable_type>s' AND
      comments.commentable_id = %<commentable_id>s
    )
    JOIN_SQL

    JOIN_COMMENT_CONTEXT = lambda { |context|
      commentable_type = context.class.polymorphic_name
      commentable_id = context.id
      format(JOIN_COMMENTS, commentable_type: commentable_type, commentable_id: commentable_id)
    }

    def self.search_documents(term, context: nil)
      results = context ? search_with_context(term, context) : search_without_context(term)
      serialize results.limit(MAX_RESULTS)
    end

    def self.search_without_context(term)
      ::User.search_by_name_and_username(term).select(*ATTRIBUTES)
    end

    def self.search_with_context(_term, context)
      join_sql = JOIN_COMMENT_CONTEXT[context]
      selects = ATTRIBUTES.map { |sym| "users.#{sym}".to_sym }
      selects << "(users.id = #{context.user_id}) as is_author"
      selects << "COUNT(comments.id) as comments_count"
      selects << "MAX(comments.created_at) as comment_at"
      # (users.id = 1) as is_author, count(comments.id) as comments_count, MAX(comments.created_at) as comment_at

      ::User.joins(join_sql)
        .group("users.id")
        .select(*selects)
        .order("is_author DESC, comments_count DESC, comment_at ASC")
    end

    def self.serialize(results)
      Search::NestedUserSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize
  end
end
