module Users
  class SuggestProminent
    RETURNING = 50

    def self.call(user, attributes_to_select: [])
      new(user, attributes_to_select: attributes_to_select).suggest
    end

    def initialize(user, attributes_to_select: [])
      @user = user
      @attributes_to_select = attributes_to_select.join(", ")
    end

    def suggest
      filtered_articles = if tags_to_consider.any?
                            Article.cached_tagged_with_any(tags_to_consider)
                          else
                            Article.featured
                          end
      user_ids = fetch_and_pluck_user_ids(filtered_articles)
      User.where(id: user_ids.uniq).order(Arel.sql("RANDOM()")).limit(RETURNING).select(attributes_to_select)
    end

    private

    attr_reader :user, :attributes_to_select

    def tags_to_consider
      user.decorate.cached_followed_tag_names
    end

    def fetch_and_pluck_user_ids(filtered_articles)
      order = Arel.sql("(hotness_score * (feed_success_score - clickbait_score)) DESC")
      user_ids = filtered_articles.order(order).limit(RETURNING * 2).pluck(:user_id) - [user.id]
      if user_ids.size > 50
        user_ids
      else
        # This is a fallback in case we don't have enough users to return
        # Will generally not be called — but maybe for brand new forems
        User.includes(:profile).without_role(:suspended).order("last_comment_at DESC").limit(RETURNING * 2).ids
      end
    end
  end
end
