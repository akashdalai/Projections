/* global checkUserLoggedIn */

function removeExistingCSRF() {
  var csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}

async function fetchBaseData() {
  const response = await fetch('/async_info/base_data');

  const jsonResponse = await response.json();
  const { token, param, broadcast, user, creator } = jsonResponse;

  if (token) {
    removeExistingCSRF();
  }

  const newCsrfParamMeta = document.createElement('meta');
  newCsrfParamMeta.name = 'csrf-param';
  newCsrfParamMeta.content = param;
  document.head.appendChild(newCsrfParamMeta);

  const newCsrfTokenMeta = document.createElement('meta');
  newCsrfTokenMeta.name = 'csrf-token';
  newCsrfTokenMeta.content = token;
  document.head.appendChild(newCsrfTokenMeta);
  document.body.dataset.loaded = 'true';

  if (broadcast) {
    document.body.dataset.broadcast = broadcast;
  }

  if (checkUserLoggedIn()) {
    document.body.dataset.user = user;
    document.body.dataset.creator = creator;
    browserStoreCache('set', user);

    setTimeout(() => {
      if (typeof ga === 'function') {
        ga('set', 'userId', JSON.parse(user).id);
      }
    }, 400);
  } else {
    // Ensure user data is not exposed if no one is logged in
    delete document.body.dataset.user;
    delete document.body.dataset.creator;
    browserStoreCache('remove');
  }
}

function initializeBodyData() {
  fetchBaseData();
}
