import { h, Component, Fragment, createRef } from 'preact';
import PropTypes from 'prop-types';
import { getInitialSearchTerm, hasInstantClick } from '../utilities/search';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { SearchForm } from './SearchForm';

const GLOBAL_MINIMIZE_KEY = 'Digit0';
const GLOBAL_SEARCH_KEY = 'Slash';
const ENTER_KEY = 'Enter';

export class Search extends Component {
  constructor(props) {
    super(props);
    this.enableSearchPageChecker = true;
    this.syncSearchUrlWithInput = this.syncSearchUrlWithInput.bind(this);
    this.searchInputRef = createRef(null);
  }

  componentWillMount() {
    const { searchTerm, setSearchTerm } = this.props;

    const searchPageChecker = () => {
      if (
        this.enableSearchPageChecker &&
        searchTerm !== '' &&
        /^http(s)?:\/\/[^/]+\/search/.exec(window.location.href) === null
      ) {
        setSearchTerm('');
      }

      setTimeout(searchPageChecker, 500);
    };

    searchPageChecker();
  }

  /**
   * Synchronizes the search input value with the search term defined in the URL.
   */
  syncSearchUrlWithInput() {
    // TODO: Consolidate search functionality.
    // Note that push states for search occur in _search.html.erb
    // in initializeSortingTabs(query)
    const { setSearchTerm } = this.props;
    const searchTerm = getInitialSearchTerm(window.location.search);

    // We set the value outside of React state so that there is no flickering of placeholder
    // to search term.
    const searchBox = this.searchInputRef.current;
    searchBox.value = searchTerm;

    // Even though we set the search term directly via the DOM, it still needs to reside
    // in component state.
    setSearchTerm(searchTerm);
  }

  componentDidMount() {
    InstantClick.on('change', this.enableSearchPageListener);

    window.addEventListener('popstate', this.syncSearchUrlWithInput);
  }

  enableSearchPageListener = () => {
    this.enableSearchPageChecker = true;
  };

  hasKeyModifiers = (event) => {
    return event.altKey || event.ctrlKey || event.metaKey || event.shiftKey;
  };

  submit = (event) => {
    if (hasInstantClick) {
      event.preventDefault();
      const { setSearchTerm } = this.props;

      const searchTerm = this.searchInputRef.current.value;
      setSearchTerm(searchTerm);
    }
  };

  search(key, value) {
    this.enableSearchPageChecker = false;

    if (hasInstantClick() && key === ENTER_KEY) {
      const { setSearchTerm } = this.props;

      setSearchTerm(value);
    }
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this.globalKeysListener);
    window.removeEventListener('popstate', this.syncSearchUrlWithInput);
    InstantClick.off &&
      InstantClick.off('change', this.enableSearchPageListener);
  }

  minimizeHeader = (event) => {
    event.preventDefault();
    document.body.classList.toggle('zen-mode');
  };

  focusOnSearchBox = (event) => {
    event.preventDefault();
    document.body.classList.remove('zen-mode');

    const searchBox = this.searchInputRef.current;
    searchBox.focus();
    searchBox.select();
  };

  render({ searchTerm }) {
    return (
      <Fragment>
        <KeyboardShortcuts
          shortcuts={{
            [GLOBAL_SEARCH_KEY]: this.focusOnSearchBox,
            [GLOBAL_MINIMIZE_KEY]: this.minimizeHeader,
          }}
        />
        <SearchForm
          searchTerm={searchTerm}
          onSearch={(event) => {
            const {
              key,
              target: { value },
            } = event;
            this.search(key, value);
          }}
          onSubmitSearch={this.submit}
          ref={this.searchInputRef}
        />
      </Fragment>
    );
  }
}

Search.propTypes = {
  searchTerm: PropTypes.string.isRequired,
  setSearchTerm: PropTypes.func.isRequired,
};
