module Moderator
  class BanishUser < ManageActivityAndRoles
    attr_reader :user, :admin

    def initialize(admin:, user:)
      @user = user
      @admin = admin
    end

    def self.call_banish(admin:, user:)
      new(user: user, admin: admin).banish
    end

    def self.call_ghost(admin:, user:)
      new(user: user, admin: admin).ghostify
    end

    def self.call_full_delete(admin:, user:)
      new(user: user, admin: admin).full_delete
    end

    def reassign_comments
      return unless user.comments.any?

      user.comments.find_each do |comment|
        comment.update_columns(user_id: @ghost.id)
        comment.save
        comment.path
      end
    end

    def reassign_articles
      return unless user.articles.any?

      user.articles.find_each do |article|
        path = "/#{@ghost.username}/" + article.slug
        article.update_columns(user_id: @ghost.id, path: path)
      end
    end

    def ghostify
      user.unsubscribe_from_newsletters
      @ghost = User.find_by(username: "ghost")
      reassign_articles
      reassign_comments
      delete_user_activity
      CacheBuster.new.bust("/#{user.username}")
      user.delete
    end

    def full_delete
      user.unsubscribe_from_newsletters
      delete_user_activity
      delete_comments
      delete_articles
      CacheBuster.new.bust("/#{user.username}")
      user.delete
    end

    def banish
      user.unsubscribe_from_newsletters if user.email?
      remove_profile_info
      handle_user_status("Ban", "spam account")
      delete_user_activity
      delete_comments
      delete_articles
      user.remove_from_algolia_index
      reassign_and_bust_username
    end

    private

    def reassign_and_bust_username
      new_name = "spam_#{rand(10_000)}"
      new_username = "spam_#{rand(10_000)}"
      if User.find_by(name: new_name) || User.find_by(username: new_username)
        new_name = "spam_#{rand(10_000)}"
        new_username = "spam_#{rand(10_000)}"
      end
      user.update_columns(name: new_name, username: new_username, old_username: user.username, profile_updated_at: Time.current)
      CacheBuster.new.bust("/#{user.old_username}")
    end

    def remove_profile_info
      user.update_columns(
        twitter_username: nil, github_username: nil, website_url: "", summary: "",
        location: "", education: "", employer_name: "", employer_url: "", employment_title: "",
        mostly_work_with: "", currently_learning: "", currently_hacking_on: "", available_for: "",
        email_public: false, facebook_url: nil, dribbble_url: nil, medium_url: nil, stackoverflow_url: nil,
        behance_url: nil, linkedin_url: nil, gitlab_url: nil, mastodon_url: nil, twitch_url: nil
      )

      user.update_columns(profile_image: "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png")
    end
  end
end
