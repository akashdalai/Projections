require "rails_helper"

describe BulkSqlDelete do
  let(:sql) do
    <<-SQL
      DELETE FROM notifications
      WHERE notifications.id IN (
        SELECT notifications.id
        FROM notifications
        WHERE created_at < '#{Time.zone.now}'
        LIMIT 1
      )
    SQL
  end
  let(:bulk_deleter) { subject }
  let(:logger) { Rails.logger }

  before { allow(Rails).to receive(:logger).and_return(logger) }

  describe "#delete_in_batches" do
    it "logs batch deletion" do
      create_list :notification, 5
      allow(logger).to receive(:info).exactly(6).times.with(
        hash_including(:tag, :statement, :duration, :rows_deleted),
      )
      bulk_deleter.delete_in_batches(sql)
      expect(logger).to have_received(:info).exactly(6).times.with(
        hash_including(:tag, :statement, :duration, :rows_deleted),
      )
    end

    it "logs errors that occur" do
      allow(logger).to receive(:error).with(
        hash_including(:tag, :statement, :exception_message, :backtrace),
      )
      allow(bulk_deleter.connection).to receive(:exec_delete).and_raise("broken")
      expect { bulk_deleter.delete_in_batches(sql) }.to raise_error("broken")
      expect(logger).to have_received(:error).with(
        hash_including(:tag, :statement, :exception_message, :backtrace),
      )
    end

    it "deletes all records in batches" do
      create_list :notification, 10
      expect { bulk_deleter.delete_in_batches(sql) }.to change(Notification, :count).from(10).to(0)
    end
  end
end
