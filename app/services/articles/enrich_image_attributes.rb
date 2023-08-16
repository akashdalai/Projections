module Articles
  module EnrichImageAttributes
    IMAGES_IN_LIQUID_TAGS_SELECTORS = [
      ".liquid-comment img", # CommentTag
      ".ltag-github-readme-tag img", # GithubReadmeTag
      ".ltag__link__pic img", # LinkTag and MediumTag profile pic
      ".ltag__link__servicename img", # MediumTag
      ".ltag__link__taglist img", # LinkTag
      ".ltag__reddit--container img", # RedditTag
      ".ltag__stackexchange--container img", # StackexchangeTag
      ".ltag__twitter-tweet img", # TweetTag
      ".ltag__user img", # UserTag and OrganizationTag
      ".ltag__user-subscription-tag img", # UserSubscriptionTag
      ".ltag_github-liquid-tag img", # GitHubIssueTag
      ".podcastliquidtag img", # PodcastTag
    ].join(", ").freeze

    def self.call(article)
      parsed_html = Nokogiri::HTML.fragment(article.processed_html)
      main_image_height = Settings::UserExperience.cover_image_fit

      # we ignore images contained in liquid tags as they are not animated
      images = parsed_html.css("img") - parsed_html.css(IMAGES_IN_LIQUID_TAGS_SELECTORS)
      return unless images.any? || article.main_image

      images.each do |img|
        src = img.attr("src")
        next unless src

        image = if URI.parse(src).relative?
                  retrieve_image_from_uploader_store(src)
                else
                  src
                end

        next if image.blank?

        img_properties = FastImage.new(image, timeout: 10)
        img["width"], img["height"] = img_properties.size
        img["data-animated"] = true if img_properties.type == :gif
      end

      if article.main_image && Settings::UserExperience.cover_image_fit == "limit"
        main_image_size = FastImage.size(article.main_image, timeout: 10)
        main_image_height = (main_image_size[1].to_f / main_image_size[0]) * 1000 if main_image_size
      end

      article.update_columns(processed_html: parsed_html.to_html, main_image_height: main_image_height)
    end

    def self.retrieve_image_from_uploader_store(src)
      filename = File.basename(src)
      uploader = ArticleImageUploader.new
      uploader.retrieve_from_store!(filename)

      return unless uploader.file.exists?

      uploader.file&.file
    end
    private_class_method :retrieve_image_from_uploader_store
  end
end
