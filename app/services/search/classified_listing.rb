module Search
  class ClassifiedListing < Base
    INDEX_NAME = "classified_listings_#{Rails.env}".freeze
    INDEX_ALIAS = "classified_listings_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/classified_listings.json"), symbolize_names: true).freeze

    class << self
      def search_documents(params:)
        query_hash = Search::QueryBuilders::ClassifiedListing.new(params).as_hash
        results = search(body: query_hash)
        results.dig("hits", "hits").map { |cl_doc| cl_doc.dig("_source") }
      end

      private

      def search(body:)
        SearchClient.search(index: INDEX_ALIAS, body: body)
      end

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 2,
            number_of_replicas: 1
          }
        else
          {
            number_of_shards: 1,
            number_of_replicas: 0
          }
        end
      end
    end
  end
end
