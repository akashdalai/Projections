module NotificationSubscriptions
  class Subscribe
    attr_reader :current_user, :comment_id, :article_id, :subscribe_to

    # Client-side needs this to be idempotent-ish, return existing subscription instead
    # of raising uniqueness exception
    def self.call(...)
      new(...).call
    end

    def initialize(current_user, comment_id: nil, article_id: nil, subscribe_to: nil)
      @current_user = current_user
      @article_id = article_id
      @comment_id = comment_id
      @subscribe_to = subscribe_to
    end

    # Client-side needs this to be idempotent-ish, return existing subscription instead
    # of raising uniqueness exception
    def call
      raise ArgumentError, "missing notifiable" if notifiable.blank?

      subscription = NotificationSubscription.find_or_initialize_by(
        user: current_user,
        config: subscription_config,
        notifiable: notifiable,
      )

      if subscription.save
        { updated: true, subscription: subscription }
      else
        { errors: subscription.errors_as_sentence }
      end
    end

    private

    def comment
      @comment ||= Comment.find(comment_id) if comment_id.present?
    end

    def article
      @article ||= Article.find(article_id) if article_id.present?
    end

    def notifiable
      @notifiable ||= determine_notifiable
    end

    def determine_notifiable
      comment || article
    end

    def subscription_config
      subscribe_to || "all_comments"
    end
  end
end
