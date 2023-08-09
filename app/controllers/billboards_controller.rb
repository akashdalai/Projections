class BillboardsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show], unless: -> { current_user }
  include BillboardHelper
  CACHE_EXPIRY_FOR_BILLBOARDS = 15.minutes.to_i.freeze

  def show
    skip_authorization
    unless session_current_user_id
      set_cache_control_headers(CACHE_EXPIRY_FOR_BILLBOARDS)
      if FeatureFlag.enabled?(Geolocation::FEATURE_FLAG)
        add_vary_header("X-Cacheable-Client-Geo")
      end
    end

    if placement_area
      if params[:username].present? && params[:slug].present?
        @article = Article.find_by(slug: params[:slug])
      end

      @billboard = DisplayAd.for_display(
        area: placement_area,
        user_signed_in: user_signed_in?,
        user_id: current_user&.id,
        article: @article ? ArticleDecorator.new(@article) : nil,
        user_tags: user_tags,
        location: client_geolocation,
      )

      if @billboard && !session_current_user_id
        set_surrogate_key_header @billboard.record_key
      end
    end

    render layout: false
  end

  private

  def placement_area
    params[:placement_area]
  end

  def user_tags
    return unless feed_targeted_tag_placement?(placement_area)

    current_user&.cached_followed_tag_names
  end

  def client_geolocation
    if session_current_user_id
      request.headers["X-Client-Geo"]
    else
      request.headers["X-Cacheable-Client-Geo"]
    end
  end
end
