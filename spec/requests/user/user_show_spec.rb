require "rails_helper"

RSpec.describe "UserShow" do
  let!(:profile) do
    create(
      :profile,
      :with_DEV_info,
      user: create(:user, :without_profile),
    )
  end
  let(:user) { profile.user }

  describe "GET /:slug (user)" do
    it "returns a 200 status when navigating to the user's page" do
      get user.path
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it "renders the proper JSON-LD for a user" do
      user.setting.update(display_email_on_profile: true)
      get user.path
      text = Nokogiri::HTML(response.body).at('script[type="application/ld+json"]').text
      response_json = JSON.parse(text)
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Person",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.user(user)
        },
        "url" => URL.user(user),
        "sameAs" => [
          "https://twitter.com/#{user.twitter_username}",
          "https://github.com/#{user.github_username}",
          "http://example.com",
        ],
        "image" => user.profile_image_url_for(length: 320),
        "name" => user.name,
        "email" => user.email,
        "description" => user.tag_line,
      )
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not render a key if no value is given" do
      incomplete_user = create(:user)
      get incomplete_user.path
      text = Nokogiri::HTML(response.body).at('script[type="application/ld+json"]').text
      response_json = JSON.parse(text)
      expect(response_json).not_to include("worksFor")
      expect(response_json.value?(nil)).to be(false)
      expect(response_json.value?("")).to be(false)
    end

    context "when user signed in" do
      before do
        sign_in user
        get user.path
      end

      describe "GET /:slug (user)" do
        it "does not render json ld" do
          expect(response.body).not_to include "application/ld+json"
        end
      end
    end

    context "when user not signed in" do
      before do
        get user.path
      end

      describe "GET /:slug (user)" do
        it "does not render json ld" do
          expect(response.body).to include "application/ld+json"
        end
      end
    end

    context "when user not signed in but internal nav triggered" do
      before do
        get "#{user.path}?i=i"
      end

      describe "GET /:slug (user)" do
        it "does not render json ld" do
          expect(response.body).not_to include "application/ld+json"
        end
      end
    end
  end

  describe "GET /users/ID.json" do
    it "404s when user not found" do
      get user_path("NaN", format: 'json')
      expect(response.status).to eq(404)
    end

    context "when user not signed in" do
      it "does not include 'suspended'" do
        get user_path(user, format: 'json')
        parsed = JSON.parse response.body
        expect(parsed.keys).to contain_exactly(*%w[id username])
      end
    end

    context "when user **is** signed in **and** trusted" do
      let(:trusted) { create :user, :trusted }

      before do
        sign_in trusted

        get user.path
      end

      it "**does** include 'suspended'" do
        get user_path(user, format: 'json')
        parsed = JSON.parse response.body
        expect(parsed.keys).to contain_exactly(*%w[id username suspended])
      end
    end
  end
end
