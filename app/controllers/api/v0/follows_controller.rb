module Api
  module V0
    class FollowsController < ApplicationController
      caches_action :followers,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes
      respond_to :json

      def followers
        return unless user_signed_in?

        query = if params[:which] == "organization_user_followers"
                  { followable_id: current_user.organization_id, followable_type: "Organization" }
                else
                  { followable_id: current_user.id, followable_type: "User" }
                end

        @follows = Follow.
          where(query).
          includes(:follower).
          page(params[:page]).
          per(80)
      end

      def create
        return unless user_signed_in?

        user_ids = params[:users].map { |h| h["id"] }
        user_ids.each do |user_id|
          Users::FollowJob.perform_later(current_user.id, user_id, "User")
        end
        render json: { outcome: "followed 50 users" }
      end
    end
  end
end
