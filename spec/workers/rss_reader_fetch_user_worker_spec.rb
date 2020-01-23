require "rails_helper"

RSpec.describe RssReaderFetchUserWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", [456]

  describe "#perform_now" do
    let(:rss_reader_service) { instance_double(RssReader) }

    before do
      allow(RssReader).to receive(:new).and_return(rss_reader_service)
      allow(rss_reader_service).to receive(:fetch_user)
    end

    context "when user found and feed_url present" do
      let(:user) { double }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:feed_url).and_return(true)
        allow(user).to receive(:id)
      end

      it "calls the service" do
        worker.perform(user.id)
        expect(rss_reader_service).to have_received(:fetch_user).with(user).once
      end
    end

    context "when no user found" do
      it "does not call the service" do
        allow(User).to receive(:find_by)
        worker.perform(456)
        expect(rss_reader_service).not_to have_received(:fetch_user)
      end
    end
  end
end
