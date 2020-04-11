import { h } from 'preact';
import { deep } from 'preact-render-spy';
import ClassifiedFiltersCategories from '../elements/classifiedFiltersCategories';

describe('<ClassifiedFiltersCategories />', () => {
  const firstCategory = {
    id: 20,
    slug: 'clojure',
    name: 'Clojure',
  };

  const secondCategory = {
    id: 21,
    slug: 'illa-iara-ques-htyashsayas-6kj8',
    name: 'Go',
  };

  const thirdCategory = {
    id: 22,
    slug: 'alle-bece-tzehj-htyashsayas-7jh9',
    name: 'csharp',
  };

  const categories = [firstCategory, secondCategory, thirdCategory];
  const defaultProps = {
    categories,
    category: 'clojure',
    onClick: () => {
      return 'onClick';
    },
  };

  const renderClassifiedFilterCategories = () =>
    deep(<ClassifiedFiltersCategories {...defaultProps} />);

  describe('Should render the links to allow navigation', () => {
    const context = renderClassifiedFilterCategories();

    it('Should render a link to listings', () => {
      expect(context.find('#listings-link').attr('href')).toBe('/listings');
    });

    it('Should render a link and a message relative to new listing', () => {
      const newListingLink = context.find('#listings-new-link');

      expect(newListingLink.attr('href')).toBe('/listings/new');
      expect(newListingLink.text()).toBe('Create a Listing');
    });

    it('Should render a link and a message relative to dashboard', () => {
      const dashboardLink = context.find('#listings-dashboard-link');

      expect(dashboardLink.attr('href')).toBe('/listings/dashboard');
      expect(dashboardLink.text()).toBe('Manage Listings');
    });
  });

  describe('Should render categories links', () => {
    const context = renderClassifiedFilterCategories();
    it('Should render the categories name and their respective links', () => {
      categories.forEach((category) => {
        const categoryLink = context.find(`#category-link-${category.id}`);
        expect(categoryLink.attr('href')).toBe(`/listings/${category.slug}`);
        expect(categoryLink.text()).toBe(category.name);
      });
    });

    it('Should set the class of the category link as "selected" when category slug matches the selected category name', () => {
      const selectedCategoryLink = context.find(`.selected`);
      expect(selectedCategoryLink.attr('id')).toBe(
        `category-link-${firstCategory.id}`,
      );
    });

    it('should set the class of the unselected categories as blank', () => {
      const unselectedCategories = categories.filter(
        (category) => category.slug !== defaultProps.category,
      );
      unselectedCategories.forEach((unselectedCategory) => {
        const unselectedCategoryLink = context.find(
          `#category-link-${unselectedCategory.id}`,
        );
        expect(unselectedCategoryLink.attr('className')).toBe('');
      });
    });
  });
});
