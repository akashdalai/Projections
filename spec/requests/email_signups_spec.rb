require "rails_helper"

RSpec.describe "EmailSignups", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /email_signups - EmailSignups#create" do
    let(:article_with_email_signup) { create(:article, body_markdown: "---\ntitle: Email Signup#{rand(1000)}\npublished: true\n---\n\n{% email_signup 'CTA text' %}") }
    let(:article) { create(:article) }

    it "creates a UserSubscription" do
      valid_attributes = { source_type: article_with_email_signup.class_name, source_id: article_with_email_signup.id }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: valid_attributes }.to_json
      end.to change(UserSubscription, :count).by(1)

      user_subscription = UserSubscription.last
      expect(user_subscription.subscriber_id).to eq user.id
      expect(user_subscription.author_id).to eq article_with_email_signup.user_id
      expect(user_subscription.user_subscription_sourceable_type).to eq article_with_email_signup.class_name
      expect(user_subscription.user_subscription_sourceable_id).to eq article_with_email_signup.id
    end

    it "returns an error for an invalid source_type" do
      invalid_source_type_attributes = { source_type: "NonExistentSourceType", source_id: "1" }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_type_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("invalid type")
    end

    it "returns an error for a source that can't be found" do
      invalid_source_attributes = { source_type: "Article", source_id: "99999999" }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("source not found")
    end

    it "returns an error for a source that doesn't have the EmailSignup liquid tag enabled" do
      invalid_source_attributes = { source_type: article.class_name, source_id: article.id }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("email signups are not enabled for the requested source")
    end

    it "returns an error for an invalid UserSubscription" do
      # Create the UserSubscription directly so it results in a
      # duplicate/invalid record and returns an error. This mimics a user
      # trying to subscribe to the same user via the same source, twice.
      UserSubscription.create(subscriber: user, author: article_with_email_signup.user, user_subscription_sourceable: article_with_email_signup)

      invalid_source_attributes = { source_type: article_with_email_signup.class_name, source_id: article_with_email_signup.id }

      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Subscriber has already been taken")
    end

    context "when rate limiting" do
      let(:rate_limiter) { RateLimitChecker.new(user) }
      let(:article_with_email_signup) { create(:article, body_markdown: "---\ntitle: Email Signup#{rand(1000)}\npublished: true\n---\n\n{% email_signup 'CTA text' %}") }
      let(:valid_attributes) { { source_type: article_with_email_signup.class_name, source_id: article_with_email_signup.id } }

      before { allow(RateLimitChecker).to receive(:new).and_return(rate_limiter) }

      it "increments rate limit for email_signup_creation" do
        allow(rate_limiter).to receive(:track_limit_by_action)
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: valid_attributes }.to_json

        expect(rate_limiter).to have_received(:track_limit_by_action).with(:email_signup_creation)
      end

      it "returns a 429 status when rate limit is reached" do
        allow(rate_limiter).to receive(:limit_by_action).and_return(true)
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: valid_attributes }.to_json

        expect(response).to have_http_status(:too_many_requests)
        expected_retry_after = RateLimitChecker::ACTION_LIMITERS.dig(:email_signup_creation, :retry_after)
        expect(response.headers["Retry-After"]).to eq(expected_retry_after)
      end
    end
  end
end
