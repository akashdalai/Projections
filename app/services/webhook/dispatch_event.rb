module Webhook
  class DispatchEvent
    def initialize(event_type, record)
      @event_type = event_type
      @record = record
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      endpoint_urls = Endpoint.for_events([event_type]).pluck(:target_url)
      return if endpoint_urls.empty?

      event_json = Event.new(event_type: event_type, payload: record.webhook_data).to_json
      endpoint_urls.each do |url|
        DispatchEventJob.perform_later(endpoint_url: url, payload: event_json)
      end
    end

    private

    attr_reader :event_type, :record
  end
end
