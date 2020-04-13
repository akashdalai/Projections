require "rails_helper"

RSpec.describe AuthorizationService, type: :service do
  before { mock_auth_hash }

  context "when authenticating through an unknown provider" do
    it "raises ProviderNotFound" do
      auth_payload = OmniAuth.config.mock_auth[:github].merge(provider: "okta")
      expect { described_class.new(auth_payload) }.to raise_error(
        Authentication::Errors::ProviderNotFound,
      )
    end
  end

  context "when authenticating through Github" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:github] }
    let!(:service) { described_class.new(auth_payload) }

    describe "new user" do
      it "creates a new user" do
        expect do
          service.get_user
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.get_user

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image)
        expect(user.github_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.github_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.get_user

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.new(auth_payload, cta_variant: "awesome").get_user

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.get_user

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339
        service = described_class.new(auth_payload)

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          service.get_user
        end
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:github]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.get_user
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"
        service = described_class.new(auth_payload)

        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.get_user
        end.not_to change(Identity, :count)
      end

      it "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.get_user
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        service = described_class.new(auth_payload)
        user = service.get_user

        expect(user.github_username).to eq(new_username)
      end

      it "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        Timecop.travel(1.minute.from_now) do
          service = described_class.new(auth_payload)
          service.get_user
        end

        user.reload
        expect(
          user.profile_updated_at.to_i > original_profile_updated_at.to_i,
        ).to be(true)
      end
    end
  end

  context "when authenticating through Twitter" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let!(:service) { described_class.new(auth_payload) }

    describe "new user" do
      it "creates a new user" do
        expect do
          service.get_user
        end.to change(User, :count).by(1)
      end

      it "creates a new identity" do
        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "extracts the proper data from the auth payload" do
        user = service.get_user

        info = auth_payload.info
        raw_info = auth_payload.extra.raw_info

        expect(user.email).to eq(info.email)
        expect(user.name).to eq(raw_info.name)
        expect(user.remote_profile_image_url).to eq(info.image.to_s.gsub("_normal", ""))
        expect(user.twitter_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.twitter_followers_count).to eq(raw_info.followers_count.to_i)
        expect(user.twitter_following_count).to eq(raw_info.friends_count.to_i)
        expect(user.twitter_username).to eq(info.nickname)
      end

      it "sets default fields" do
        user = service.get_user

        expect(user.password).to be_present
        expect(user.signup_cta_variant).to be_nil
        expect(user.saw_onboarding).to be(false)
        expect(user.editor_version).to eq("v2")
      end

      it "sets the correct sign up cta variant" do
        user = described_class.new(auth_payload, cta_variant: "awesome").get_user

        expect(user.signup_cta_variant).to eq("awesome")
      end

      it "sets remember_me for the new user" do
        user = service.get_user

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "queues a slack message to be sent for a user whose identity is brand new" do
        auth_payload.extra.raw_info.created_at = 1.minute.ago.rfc3339
        service = described_class.new(auth_payload)

        sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
          service.get_user
        end
      end
    end

    describe "existing user" do
      let(:user) { create(:user, :with_identity, identities: [:twitter]) }

      before do
        auth_payload.info.email = user.email
      end

      it "doesn't create a new user" do
        expect do
          service.get_user
        end.not_to change(User, :count)
      end

      it "creates a new identity if the user doesn't have one" do
        user = create(:user)
        auth_payload.info.email = user.email
        auth_payload.uid = "#{user.email}-#{rand(10_000)}"
        service = described_class.new(auth_payload)

        expect do
          service.get_user
        end.to change(Identity, :count).by(1)
      end

      it "does not create a new identity if the user has one" do
        expect do
          service.get_user
        end.not_to change(Identity, :count)
      end

      it "updates the proper data from the auth payload" do
        # simulate changing twitter data
        auth_payload.extra.raw_info.followers_count = rand(100).to_s
        auth_payload.extra.raw_info.friends_count = rand(100).to_s

        service = described_class.new(auth_payload)
        user = service.get_user

        raw_info = auth_payload.extra.raw_info

        expect(user.twitter_created_at.to_i).to eq(Time.zone.parse(raw_info.created_at).to_i)
        expect(user.twitter_followers_count).to eq(raw_info.followers_count.to_i)
        expect(user.twitter_following_count).to eq(raw_info.friends_count.to_i)
      end

      it "sets remember_me for the existing user" do
        user.update_columns(remember_token: nil, remember_created_at: nil)

        service.get_user
        user.reload

        expect(user.remember_me).to be(true)
        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end

      it "updates the username when it is changed on the provider" do
        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        service = described_class.new(auth_payload)
        user = service.get_user

        expect(user.twitter_username).to eq(new_username)
      end

      it "updates profile_updated_at when the username is changed" do
        original_profile_updated_at = user.profile_updated_at

        new_username = "new_username#{rand(1000)}"
        auth_payload.info.nickname = new_username

        Timecop.travel(1.minute.from_now) do
          service = described_class.new(auth_payload)
          service.get_user
        end

        user.reload
        expect(
          user.profile_updated_at.to_i > original_profile_updated_at.to_i,
        ).to be(true)
      end
    end
  end
end
