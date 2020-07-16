/*
  global selectNavigation
*/
import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export class CategoryLinks extends Component {
  triggerMobileNavigation = () => {
    selectNavigation('mobile_nav_listings');
  };

  render() {
    const { categories, selectedCategory } = this.props;
    
    this.triggerMobileNavigation();

    return (
      <div className="block m:hidden">
        <select
          id="mobile_nav_listings"
          class="crayons-select"
        >
          <option
            value="/listings"
            selected={selectedCategory === '' && true}
          >
            All listings
          </option>

          {categories.map((category) => {
            return (
              <option
                value={`/listings/${category.slug}`}
                selected={category.slug === selectedCategory && true}
              >
                {category.name}
              </option>
            );
          })}
        </select>
      </div>
    );
  }
};

CategoryLinks.propTypes = {
  categories: PropTypes.arrayOf(
    PropTypes.shape({
      slug: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  selectedCategory: PropTypes.string.isRequired,
};

export default CategoryLinks;
