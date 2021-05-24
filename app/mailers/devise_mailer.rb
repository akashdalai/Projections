class DeviseMailer < Devise::Mailer
  before_action :use_settings_general_values

  def use_settings_general_values
    Devise.mailer_sender =
      "#{Settings::Community.community_name} <#{Settings::General.email_addresses[:default]}>"
    ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
  end
end
