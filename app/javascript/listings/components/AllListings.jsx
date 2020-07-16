import { h } from 'preact';
import PropTypes from 'prop-types';
import { SingleListing } from '../singleListing/SingleListing';

const AllListings = ({
  listings,
  onAddTag,
  onChangeCategory,
  currentUserId,
  onOpenModal,
}) => {
  return (
    <main class="crayons-layout__content">
      <div className="listings-columns" id="listings-results">
        {listings.map((listing) => (
          <SingleListing
            onAddTag={onAddTag}
            onChangeCategory={onChangeCategory}
            listing={listing}
            currentUserId={currentUserId}
            onOpenModal={onOpenModal}
            isOpen={false}
          />
        ))}
      </div>
    </main>
  );
};

AllListings.propTypes = {
  currentUserId: PropTypes.number,
  listings: PropTypes.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  onOpenModal: PropTypes.func.isRequired,
};

AllListings.defaultProps = {
  currentUserId: null,
};

export default AllListings;
