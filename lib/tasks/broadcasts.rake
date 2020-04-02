namespace :broadcasts do
  desc "Send Welcome Notifications once a day"
  task broadcast_welcome_notification_flow: :environment do
    # In order to prevent new users from receiving multiple welcome notifications in a day,
    # a feature_live_date is required. The script will only be effective after feature_live_date
    # and will ultimately be superseded by 7.days.ago when it's larger than feature_live_date
    feature_live_date = Broadcasts::WelcomeNotification::Generator::NOTIFICATIONS_SET_LIVE_DATE
    week_ago = 7.days.ago
    latest_date = feature_live_date > week_ago ? feature_live_date : week_ago

    User.where("created_at > ?", latest_date).find_each do |user|
      Broadcasts::WelcomeNotification::Generator.call(user.id)
    end
  end
end
