import PropTypes from 'prop-types';
import { h } from 'preact';

const ActionButtons = ({ isDraft, listingUrl, editUrl }) => {
  return (
    <div className="listing-row-actions">
      {/* <a className="dashboard-listing-bump-button cta pill black">BUMP</a> */}
      {isDraft && (
      <a
        href={listingUrl}
        className="dashboard-listing-edit-button cta pill yellow"
      >
        DRAFT
      </a>
      )}
      <a
        href={editUrl}
        className="dashboard-listing-edit-button cta pill green"
      >
        EDIT
      </a>
      {/* <a className="dashboard-listing-delete-button cta pill red">DELETE</a> */}
    </div>
  )
}

ActionButtons.propTypes = {
  isDraft: PropTypes.bool.isRequired,
  listingUrl: PropTypes.string.isRequired,
  editUrl: PropTypes.string.isRequired,
}

export default ActionButtons;