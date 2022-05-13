require "rails_helper"

RSpec.describe Admin::GDPRDeleteRequestsQuery, type: :query do
  subject { described_class.call(relation: ::GDPRDeleteRequest.all, search: nil) }

  let!(:gdpr_delete_request_1) { create(:gdpr_delete_request, username: "delete_1", email: "delete_1@test.com") }
  let!(:gdpr_delete_request_2) { create(:gdpr_delete_request, username: "delete_2", email: "delete_2@test.com") }
  let!(:gdpr_delete_request_3) { create(:gdpr_delete_request, username: "delete_3", email: "delete_3@test.com") }
  let!(:gdpr_delete_request_11) { create(:gdpr_delete_request, username: "delete_11", email: "delete_11@test.com") }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all users" do
        # rubocop:disable Layout/LineLength
        expect(described_class.call).to include(gdpr_delete_request_1, gdpr_delete_request_2, gdpr_delete_request_3, gdpr_delete_request_11)
        # rubocop:enable Layout/LineLength
      end
    end

    context "when searching for a user by username" do
      let(:search) { { search: "delete_1" } }

      it { is_expected.to include(gdpr_delete_request_1) }
    end

    context "when searching for a user by email" do
      let(:search) { { search: "delete_1@test.com" } }

      it { is_expected.to include(gdpr_delete_request_1) }
    end

    context "when searching for ambiguous terms that matches multiple users" do
      let(:search) { { search: "delete_1" } }

      it { is_expected.to include(gdpr_delete_request_1, gdpr_delete_request_11) }
    end

    context "when searching for ambiguous terms that matches both emails and usernames" do
      let(:search) { { search: "delete" } }

      # rubocop:disable Layout/LineLength
      it { is_expected.to include(gdpr_delete_request_1, gdpr_delete_request_2, gdpr_delete_request_3, gdpr_delete_request_11) }
      # rubocop:enable Layout/LineLength
    end
  end
end
