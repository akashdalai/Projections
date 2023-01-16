require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Followers" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:follower1) { create(:user) }
  let(:follower2) { create(:user) }

  before do
    follower1.follow(user)
    follower2.follow(user)
    user.reload
  end

  describe "GET /followers/users" do
    path "/api/followers/users" do
      get "Followers" do
        tags "followers"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve a list of the followers they have.
        "Followers" are users that are following other users on the website.
        It supports pagination, each page will contain 80 followers by default.
        DESCRIBE
        operationId "getFollowers"
        produces "application/json"

        parameter "$ref": "#/components/parameters/pageParam"
        parameter "$ref": "#/components/parameters/perPageParam30to1000"
        parameter name: :sort, in: :query, required: false,
                  description: "Default is 'created_at'. Specifies the sort order for the created_at param of the follow
                                relationship. To sort by newest followers first (descending order) specify
                                ?sort=-created_at.",
                  schema: { type: :string },
                  example: "created_at"
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
