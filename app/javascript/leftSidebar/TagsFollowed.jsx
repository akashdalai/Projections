import { h, Fragment } from 'preact';
import ahoy from 'ahoy.js';
import PropTypes from 'prop-types';

export const TagsFollowed = ({ tags = [] }) => {
  const trackSidebarTagClick = (event) => {
    // Temporary Ahoy Stats for usage reports
    ahoy.track('Tag sidebar click', { option: event.target.href });
  };

  return (
    <Fragment>
      {tags.map((tag) =>
        tag.points >= 1 ? (
          <div
            key={tag.id}
            className="sidebar-nav-element"
            id={`sidebar-element-${tag.name}`}
          >
            <a
              title={`${tag.name} tag`}
              onClick={trackSidebarTagClick}
              className="crayons-link crayons-link--block"
              href={`/t/${tag.name}`}
            >
              {`#${tag.name}`}
            </a>
          </div>
        ) : null,
      )}
    </Fragment>
  );
};

TagsFollowed.displayName = 'TagsFollowed';

const tagPropShape = PropTypes.shape({
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  hotness_score: PropTypes.number.isRequired,
  points: PropTypes.number.isRequired,
  bg_color_hex: PropTypes.string.isRequired,
  text_color_hex: PropTypes.string.isRequired,
});

TagsFollowed.propTypes = {
  testTagsFollowedProps(props, tags, TagsFollowed) {
    const tagsProp = props[tags];

    if (tagsProp) {
      if (!Array.isArray(tagsProp))
        return new Error(`${tags} must be an array`);

      tagsProp.forEach((elem) =>
        PropTypes.checkPropTypes(
          tagPropShape,
          elem,
          'prop',
          `${TagsFollowed}.${tags}`,
        ),
      );
    }
  },
};
