import { h, render } from 'preact';
import PropTypes from 'prop-types';
import { Article, LoadingArticle } from '../articles';
import { Feed } from '../articles/Feed';
import { TodaysPodcasts, PodcastEpisode } from '../podcasts';
import { articlePropTypes } from '../common-prop-types';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

/**
 * Sends analytics about the featured article.
 *
 * @param {number} articleId
 */
function sendFeaturedArticleGoogleAnalytics(articleId) {
  (function logFeaturedArticleImpressionGA() {
    if (!window.ga || !ga.create) {
      setTimeout(logFeaturedArticleImpressionGA, 20);
      return;
    }

    ga(
      'send',
      'event',
      'view',
      'featured-feed-impression',
      `articles-${articleId}`,
      null,
    );
  })();
}

function sendFeaturedArticleAnalyticsGA4(articleId) {
  (function logFeaturedArticleImpressionGA4() {
    if (!window.gtag) {
      setTimeout(logFeaturedArticleImpressionGA4, 20);
      return;
    }

    gtag('event', 'featured-feed-impression', {
      event_category: 'view',
      event_label: `articles-${articleId}`,
    });
  })();
}

function feedConstruct(
  pinnedItem,
  imageItem,
  feedItems,
  podcastEpisodes,
  bookmarkedFeedItems,
  bookmarkClick,
  currentUserId,
  timeFrame,
) {
  const commonProps = {
    bookmarkClick,
  };

  const feedStyle = JSON.parse(document.body.dataset.user).feed_style;

  if (imageItem) {
    sendFeaturedArticleGoogleAnalytics(imageItem.id);
    sendFeaturedArticleAnalyticsGA4(imageItem.id);
  }

  return feedItems.map((item) => {
    // billboard is an html string
    if (typeof item === 'string') {
      return (
        <div
          key={item.id}
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: item,
          }}
        />
      );
    }

    if (typeof item === 'object') {
      // For "saveable" props, "!=" is used instead of "!==" to compare user_id
      // and currentUserId because currentUserId is a String while user_id is an Integer

      if (item.id === pinnedItem?.id && timeFrame === '') {
        return (
          <Article
            {...commonProps}
            key={item.id}
            article={pinnedItem}
            pinned={true}
            feedStyle={feedStyle}
            isBookmarked={bookmarkedFeedItems.has(pinnedItem.id)}
            saveable={pinnedItem.user_id != currentUserId}
          />
        );
      }

      if (item.id === imageItem?.id) {
        return (
          <Article
            {...commonProps}
            key={item.id}
            article={imageItem}
            isFeatured
            feedStyle={feedStyle}
            isBookmarked={bookmarkedFeedItems.has(imageItem.id)}
            saveable={imageItem.user_id != currentUserId}
          />
        );
      }

      if (item.podcast) {
        return <PodcastEpisodes key={item.id} episodes={podcastEpisodes} />;
      }

      if (item.class_name === 'Article') {
        return (
          <Article
            {...commonProps}
            key={item.id}
            article={item}
            feedStyle={feedStyle}
            isBookmarked={bookmarkedFeedItems.has(item.id)}
            saveable={item.user_id != currentUserId}
          />
        );
      }
    }
  });
}

const FeedLoading = () => (
  <div data-testid="feed-loading">
    <LoadingArticle version="featured" />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
  </div>
);

const PodcastEpisodes = ({ episodes }) => (
  <TodaysPodcasts>
    {episodes.map((episode) => (
      <PodcastEpisode episode={episode} key={episode.podcast.id} />
    ))}
  </TodaysPodcasts>
);

PodcastEpisodes.defaultProps = {
  episodes: [],
};

PodcastEpisodes.propTypes = {
  episodes: PropTypes.arrayOf(articlePropTypes),
};

/**
 * Renders the main feed.
 */
export const renderFeed = async (timeFrame) => {
  const feedContainer = document.getElementById('homepage-feed');

  const { currentUser } = await getUserDataAndCsrfToken();
  const currentUserId = currentUser && currentUser.id;

  const callback = ({
    pinnedItem,
    imageItem,
    feedItems,
    podcastEpisodes,
    bookmarkedFeedItems,
    bookmarkClick,
  }) => {
    if (feedItems.length === 0) {
      // Fancy loading ✨
      return <FeedLoading />;
    }

    return (
      <div>
        {feedConstruct(
          pinnedItem,
          imageItem,
          feedItems,
          podcastEpisodes,
          bookmarkedFeedItems,
          bookmarkClick,
          currentUserId,
          timeFrame,
        )}
      </div>
    );
  };

  render(
    <Feed timeFrame={timeFrame} renderFeed={callback} />,
    feedContainer,
    feedContainer.firstElementChild,
  );
};
