require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Users", type: :request do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:banned_user) { create(:user) }
  let(:article) { create(:article, user: banned_user, published: true) }
  let(:comment) { create(:comment, user: banned_user, article: article) }

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
    user.add_role(:admin)
  end

  describe "PUT /users/:id/unpublish" do
    before do
      user.add_role(:admin)
    end

    path "/api/users/{id}/unpublish" do
      put "Unpublish an User's Articles and Comments" do
        tags "articles", "comments", "users"
        description "This endpoint allows the client to unpublish all of the articles and
comments created by a user.

The user associated with the API key must have either the 'admin' or 'moderator' role.

This specified users's article and comments will be unpublished and will no longer be
visible to the public. They will remain in the database and will set back to draft status
on the specified user's  dashboard. Any notifications associated with the specified user's
articles and comments will be deleted.

Note this endpoint unpublishes articles and comments asychronously: it will return a 204 NO CONTENT
status code immediately, but the articles and comments will not be unpublished until the
request is completed on the server."
        operationId "unpublishUser"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the user to unpublish.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        response "204", "Article successfully unpublished" do
          let(:"api-key") { api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "401", "Unauthorized" do
          let(:regular_user) { create(:user) }
          let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
          let(:"api-key") { low_security_api_secret.secret }
          let(:id) { banned_user.id }
          add_examples

          run_test!
        end

        response "204", "Unknown User ID (still accepted for async processing" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 10_000 }
          add_examples

          run_test!
        end
      end
    end
  end

  #   describe "PUT /users/:id/suspend" do
  #     before do
  #       user.add_role(:admin)
  #     end

  #     path "/api/users/{id}/suspend" do
  #       put "Suspend a User" do
  #         tags "articles", "comments", "users"
  #         description "This endpoint allows the client to unpublish all of the articles and
  # comments created by a user.

  # The user associated with the API key must have either the 'admin' or 'moderator' role.

  # This specified users's article and comments will be unpublished and will no longer be
  # visible to the public. They will remain in the database and will set back to draft status
  # on the specified user's  dashboard. Any notifications associated with the specified user's
  # articles and comments will be deleted.

  # Note this endpoint unpublishes articles and comments asychronously: it will return a 204 NO CONTENT
  # status code immediately, but the articles and comments will not be unpublished until the
  # request is completed on the server."
  #         operationId "unpublishUser"
  #         produces "application/json"
  #         parameter name: :id, in: :path, required: true,
  #                   description: "The ID of the user to unpublish.",
  #                   schema: {
  #                     type: :integer,
  #                     format: :int32,
  #                     minimum: 1
  #                   },
  #                   example: 1

  #         response "204", "Article successfully unpublished" do
  #           let(:"api-key") { api_secret.secret }
  #           let(:id) { banned_user.id }
  #           add_examples

  #           run_test!
  #         end

  #         response "401", "Unauthorized" do
  #           let(:regular_user) { create(:user) }
  #           let(:low_security_api_secret) { create(:api_secret, user: regular_user) }
  #           let(:"api-key") { low_security_api_secret.secret }
  #           let(:id) { banned_user.id }
  #           add_examples

  #           run_test!
  #         end

  #         response "204", "Unknown User ID (still accepted for async processing" do
  #           let(:"api-key") { api_secret.secret }
  #           let(:id) { 10_000 }
  #           add_examples

  #           run_test!
  #         end
  #       end
  #     end
  #   end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
