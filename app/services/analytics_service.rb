class AnalyticsService
  def initialize(user_or_org, start_date: "", end_date: "", article_id: nil)
    @user_or_org = user_or_org
    @article_id = article_id
    @start_date = Time.zone.parse(start_date.to_s)&.beginning_of_day
    @end_date = Time.zone.parse(end_date.to_s)&.end_of_day || Time.current.end_of_day

    load_data
  end

  # Computes total counts for comments, reactions, follows and page views
  def totals
    {
      comments: { total: comment_data.size },
      follows: { total: follow_data.size },
      reactions: calculate_reactions_totals,
      page_views: calculate_page_views_totals
    }
  end

  # Computes counts for comments, reactions, follows and page views per each day
  def grouped_by_day
    return {} unless start_date && end_date

    # cache all stats in the date range for the requested user or organization
    cache_key = "analytics-for-dates-#{start_date}-#{end_date}-#{user_or_org.class.name}-#{user_or_org.id}"
    cache_key = "#{cache_key}-article-#{article_id}" if article_id

    Rails.cache.fetch(cache_key, expires_in: 7.days) do
      # 1. calculate all stats using group queries at once
      comments_stats_per_day = calculate_comments_stats_per_day(comment_data)
      follows_stats_per_day = calculate_follows_stats_per_day(follow_data)
      reactions_stats_per_day = calculate_reactions_stats_per_day(reaction_data)
      page_views_stats_per_day = calculate_page_views_stats_per_day(page_view_data)

      # 2. build the final hash, one per each day
      stats = {}
      (start_date.to_date..end_date.to_date).each do |date|
        stats[date.iso8601] = stats_per_day(
          date,
          comments_stats: comments_stats_per_day,
          follows_stats: follows_stats_per_day,
          reactions_stats: reactions_stats_per_day,
          page_views_stats: page_views_stats_per_day,
        )
      end

      stats
    end
  end

  # Returns the list of referrers
  def referrers(top: 20)
    # count_all is the name of the field autogenerated by Rails with COUNT(*)
    counts = page_view_data.group(:domain).order(count_all: :desc).limit(top).count
    # we transform this in a list of hashes in case we need to add more keys
    domains = counts.map { |domain, count| { domain: domain, count: count } }

    { domains: domains }
  end

  private

  attr_reader(
    :user_or_org, :article_id, :start_date, :end_date,
    :article_data, :reaction_data, :comment_data, :follow_data, :page_view_data
  )

  def load_data
    @article_data = Article.published.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id)
    if @article_id
      @article_data = @article_data.where(id: @article_id)

      # check article_id is published and belongs to the user/org
      raise ArgumentError, "You can't view this article's stats" unless @article_data.exists?

      article_ids = [@article_id]
    else
      article_ids = @article_data.ids
    end

    # prepare relations for metrics
    @comment_data = Comment
      .where(commentable_id: article_ids, commentable_type: "Article")
      .where("score > 0")
    @follow_data = Follow
      .where(followable_type: user_or_org.class.name, followable_id: user_or_org.id)
    @reaction_data = Reaction.public_category
      .where(reactable_id: article_ids, reactable_type: "Article")
    @page_view_data = PageView.where(article_id: article_ids)

    # filter data by date if needed
    return unless start_date && end_date

    @comment_data = @comment_data.where(created_at: @start_date..@end_date)
    @reaction_data = @reaction_data.where(created_at: @start_date..@end_date)
    @page_view_data = @page_view_data.where(created_at: @start_date..@end_date)
  end

  def calculate_reactions_totals
    # NOTE: the order of the keys needs to be the same as the one of the counts
    keys = %i[total like readinglist unicorn]
    counts = reaction_data.pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'like')"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'readinglist')"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'unicorn')"),
    )

    # this transforms the counts, eg. [1, 0, 1, 0]
    # in a hash, eg. {total: 1, like: 0, readinglist: 1, unicorn: 0}
    keys.zip(counts).to_h
  end

  def calculate_page_views_totals
    total_views = article_data.sum(:page_views_count)
    logged_in_page_view_data = page_view_data.where.not(user_id: nil)
    average = logged_in_page_view_data.pick(Arel.sql("AVG(time_tracked_in_seconds)"))
    average_read_time_in_seconds = (average || 0).round # average is a BigDecimal

    {
      total: total_views,
      average_read_time_in_seconds: average_read_time_in_seconds,
      total_read_time_in_seconds: average_read_time_in_seconds * total_views
    }
  end

  def calculate_comments_stats_per_day(comment_data)
    # AR returns a hash with date => count, we transform it using ISO dates for convenience
    comment_data.group("DATE(created_at)").count.transform_keys(&:iso8601)
  end

  def calculate_follows_stats_per_day(follow_data)
    # AR returns a hash with date => count, we transform it using ISO dates for convenience
    follow_data.group("DATE(created_at)").count.transform_keys(&:iso8601)
  end

  def calculate_reactions_stats_per_day(reaction_data)
    # we issue one single query that contains all requested aggregates
    # and that groups them by date
    reactions = reaction_data.select(
      Arel.sql("DATE(created_at)").as("date"),
      Arel.sql("COUNT(*)").as("total"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'like')").as("like"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'readinglist')").as("readinglist"),
      Arel.sql("COUNT(*) FILTER (WHERE category = 'unicorn')").as("unicorn"),
    ).group("DATE(created_at)")

    # this transforms the collection of pseudo Reaction objects previously selected
    # in a hash, eg. {total: 1, like: 0, readinglist: 1, unicorn: 0}
    reactions.each_with_object({}) do |reaction, hash|
      hash[reaction.date.iso8601] = {
        total: reaction.total,
        like: reaction.like,
        readinglist: reaction.readinglist,
        unicorn: reaction.unicorn
      }
    end
  end

  def calculate_page_views_stats_per_day(page_view_data)
    # we issue one single query that contains all requested aggregates
    # and that groups them by date
    page_views = page_view_data.select(
      Arel.sql("DATE(created_at)").as("date"),
      Arel.sql("SUM(counts_for_number_of_views)").as("total"),
      # count the average only for logged in users
      Arel.sql("AVG(time_tracked_in_seconds) FILTER (WHERE user_id IS NOT NULL)").as("average"),
    ).group("DATE(created_at)")

    # this transforms the collection of pseudo PageView objects previously selected
    # in a hash, eg. {total: 2, average_read_time_in_seconds: 10, total_read_time_in_seconds: 20}
    page_views.each_with_object({}) do |page_view, hash|
      average = (page_view.average || 0).round # average is a BigDecimal
      hash[page_view.date.iso8601] = {
        total: page_view.total,
        average_read_time_in_seconds: average,
        total_read_time_in_seconds: page_view.total * average
      }
    end
  end

  def stats_per_day(date, comments_stats:, follows_stats:, reactions_stats:, page_views_stats:)
    # we need these defaults because SQL doesn't return any data for dates that don't have any
    default_reactions_stats = { total: 0, like: 0, readinglist: 0, unicorn: 0 }
    default_page_views_stats = { total: 0, average_read_time_in_seconds: 0, total_read_time_in_seconds: 0 }
    iso_date = date.iso8601

    {
      comments: { total: comments_stats[iso_date] || 0 },
      follows: { total: follows_stats[iso_date] || 0 },
      reactions: reactions_stats[iso_date] || default_reactions_stats,
      page_views: page_views_stats[iso_date] || default_page_views_stats
    }
  end
end
