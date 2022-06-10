import {
  showWindowModal,
  closeWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';

/**
 * Details panels will automatically expand on click when required.
 * We want to make sure only _one_ panel is expanded at any given time,
 * so here we collapse any which don't match the click's target
 */
const initializeFilterDetailsToggles = () => {
  const allDetailsPanels = document.querySelectorAll(
    `#${WINDOW_MODAL_ID} details`,
  );
  allDetailsPanels?.forEach((panel) => {
    panel.addEventListener('toggle', ({ target }) => {
      // If the panel is closing, do nothing
      if (target.getAttribute('open') === null) {
        return;
      }

      const {
        dataset: { section: clickedSection },
      } = target;

      document
        .querySelectorAll(`#${WINDOW_MODAL_ID} details[open]`)
        .forEach((openPanel) => {
          if (openPanel.dataset?.section !== clickedSection) {
            openPanel.removeAttribute('open');
          }
        });
    });
  });
};

const initializeModalCloseButton = () =>
  document
    .querySelector(`#${WINDOW_MODAL_ID} .js-filter-modal-cancel-btn`)
    .addEventListener('click', closeWindowModal);

/**
 * Roles list is dynamically expanded and collapsed by this toggle button
 */
const initializeShowHideRoles = () => {
  document
    .querySelector('.js-expand-roles-btn')
    .addEventListener('click', ({ target }) => {
      const initiallyHiddenRoles = document.querySelector(
        '.js-initially-hidden-roles',
      );

      const isCurrentlyHidden =
        initiallyHiddenRoles.classList.contains('hidden');

      initiallyHiddenRoles.classList.toggle('hidden');
      target.setAttribute('aria-pressed', isCurrentlyHidden ? 'true' : 'false');
      target.innerText = `See ${isCurrentlyHidden ? 'fewer' : 'more'} roles`;
    });
};

let cachedFiltersModalContent;

export const initializeFiltersModal = () => {
  document.querySelectorAll('.js-open-filter-modal-btn').forEach((button) => {
    button.addEventListener('click', () => {
      // We need to remove the originally "hidden" modal content from the page to prevent conflicts with input IDs
      if (!cachedFiltersModalContent) {
        const filterModalContent = document.querySelector('.js-filters-modal');
        cachedFiltersModalContent = filterModalContent.innerHTML;
        filterModalContent.remove();
      }

      showWindowModal({
        modalContent: cachedFiltersModalContent,
        showHeader: false,
        sheet: true,
        sheetAlign: 'right',
        size: 'small',
        onOpen: () => {
          initializeModalCloseButton();
          initializeFilterDetailsToggles();
          initializeShowHideRoles();
        },
      });
    });
  });
};
