function toggleBurgerMenu() {
  document.body.classList.toggle('hamburger-open');
}

function showMoreMenu({ target }) {
  target.nextElementSibling.classList.remove('hidden');
  target.classList.add('hidden');
}

/**
 * Gets a reference to InstantClick
 *
 * @returns {Promise<object>} The global instance of InstantClick.
 */
export async function getInstantClick() {
  return new Promise((resolve) => {
    const timer = setInterval(() => {
      if (InstantClick) {
        clearInterval(timer);
        resolve(InstantClick);
      }
    });
  });
}

/**
 * Initializes the hamburger menu for mobile navigation
 *
 * @param {HTMLElement[]} menus
 * @param {HTMLElement[]} moreMenus
 */
export function initializeMobileMenu(menus, moreMenus) {
  menus.forEach((trigger) => {
    trigger.addEventListener('click', toggleBurgerMenu);
  });

  moreMenus.forEach((trigger) => {
    trigger.addEventListener('click', showMoreMenu);
  });
}

/**
 * Sets the icon link visually for the current page if the current page
 * is one of the main icon links of the top navigation.
 *
 * @param {string} currentPage
 * @param {[string, HTMLElement][]} pageEntries
 */
export function setCurrentPageIconLink(currentPage, pageEntries) {
  pageEntries
    // Filter out nulls (means the user is logged out so most icons are not in the logged out view)
    .filter(([, iconLink]) => iconLink)
    .forEach(([page, iconLink]) => {
      if (currentPage === page) {
        iconLink.blur();
        iconLink.classList.add('crayons-header__link--current');
      } else {
        iconLink.classList.remove('crayons-header__link--current');
      }
    });
}
