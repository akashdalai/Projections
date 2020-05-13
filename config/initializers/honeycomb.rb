class CustomSampler
  extend Honeycomb::DeterministicSampler

  def self.sample(fields)
    noisy = Set[
      'GET rails-settings-cached/v1',
      'TIME',
      'BEGIN',
      'COMMIT',
    ]
    if noisy === fields["redis.command"] or noisy === fields["sql.active_record.sql"]
      rate = 100
      [should_sample(rate, fields["trace.trace_id"]), rate]
    elsif fields["redis.command"].start_with?("BRPOP")
      rate = 1000
      [should_sample(rate, fields["trace.trace_id"]), rate]
    elsif fields["redis.command"].start_with?("INCRBY")
      rate = 100
      [should_sample(rate, fields["trace.trace_id"]), rate]
    elsif fields["redis.command"].start_with?("TTL")
      rate = 100
      [should_sample(rate, fields["trace.trace_id"]), rate]
    else
      [true, 1]
    end
  end
end

if Rails.env.test? || ApplicationConfig["HONEYCOMB_API_KEY"].blank?
  Honeycomb.configure do |config|
    config.client = Libhoney::TestClient.new
  end
else
  honeycomb_api_key = ApplicationConfig["HONEYCOMB_API_KEY"]

  # Honeycomb automatic Rails integration
  Honeycomb.configure do |config|
    config.write_key = honeycomb_api_key
    if ENV["HONEYCOMB_DISABLE_AUTOCONFIGURE"]
      config.dataset = "background-work"
    else
      config.dataset = "rails"
      config.notification_events = %w[
        sql.active_record
        render_template.action_view
        render_partial.action_view
        render_collection.action_view
        process_action.action_controller
        send_file.action_controller
        send_data.action_controller
        deliver.action_mailer
      ].freeze

      # Scrub unused data to save space in Honeycomb
      config.presend_hook do |fields|
        if fields.key?("redis.command")
          fields["redis.command"] = fields["redis.command"].slice(0, 300)
        elsif fields.key?("sql.active_record.binds")
          fields.delete("sql.active_record.binds")
          fields.delete("sql.active_record.datadog_span")
        end
      end
      # Sample away highly redundant events
      config.sample_hook do |fields|
        CustomSampler.sample(fields)
      end
    end
  end
end
