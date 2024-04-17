module AlgoliaSearch
  class SearchIndexWorker
    include Sidekiq::Worker
    sidekiq_options queue: :algolia_indexing, retry: 5

    def perform(klass, id, remove)
      return unless Settings::General.algolia_search_enabled?

      record = klass.constantize

      if remove
        index = AlgoliaSearch.client.init_index(record.index_name)
        index.delete_object(id)
      else
        record.find(id).index!
      end
    end
  end
end
