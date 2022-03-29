function setDefaultUsername(event) {
  if (
    document
      .getElementsByClassName('js-creator-signup-username-row')[0]
      .classList.contains('hidden')
  ) {
    const name = event.target.value;
    // It's the first user and so we can assume that this username is not taken.
    const usernameHint = createUsernameHint(name);
    setUsernameHint(usernameHint);
    setUsernameField(usernameHint);
    showHintRow();
  }
}

function createUsernameHint(name) {
  return name
    .toLowerCase()
    .replace(/[^a-zA-Z0-9]/g, '_')
    .substr(0, 30);
}

function showHintRow() {
  const hintRow = document.getElementsByClassName(
    'js-creator-signup-username-hint-row',
  )[0];
  hintRow.classList.remove('hidden');
}

function setUsernameHint(usernameHint) {
  const usernameHintDisplay = document.getElementsByClassName(
    'js-creator-signup-username-hint',
  )[0];
  usernameHintDisplay.innerHTML = usernameHint;
}

function setUsernameField(usernameHint) {
  const usernameField = document.getElementsByClassName(
    'js-creator-signup-username',
  )[0];
  usernameField.value = usernameHint;
}

function showUsernameField() {
  const usernameRow = document.getElementsByClassName(
    'js-creator-signup-username-row',
  )[0];
  usernameRow.classList.remove('hidden');
  focusUsernameInput(usernameRow);
  hideHintRow();
}

function focusUsernameInput(usernameRow) {
  // A timer with a count of 0 will run when the thread becomes idle
  window.setTimeout(() => {
    usernameRow.getElementsByTagName('input')[0].focus();
  }, 0);
}

function hideHintRow() {
  const hintRow = document.getElementsByClassName(
    'js-creator-signup-username-hint-row',
  )[0];
  hintRow.classList.add('hidden');
}

function setTogglePasswordEvent(targetClass) {
  function togglePasswordMask(event) {
    event.preventDefault();
    visible = !visible;
    toggleAriaPressed(visible);
    togglePasswordType(visible);
    toggleEyeIcons(visible);
  }

  function toggleAriaPressed(visible) {
    visibility.setAttribute('aria-pressed', visible);
  }

  function togglePasswordType(visible) {
    const passwordType = visible ? 'text' : 'password';
    passwordField.type = passwordType;
  }

  function toggleEyeIcons(visible) {
    eyeOffIcon.classList.toggle('hidden', !visible);
    eyeIcon.classList.toggle('hidden', visible);
  }

  let visible = false;
  const targetWrapper = document.getElementsByClassName(targetClass)[0];
  const eyeIcon = targetWrapper.getElementsByClassName('js-eye')[0];
  const eyeOffIcon = targetWrapper.getElementsByClassName('js-eye-off')[0];
  const passwordField = targetWrapper.getElementsByClassName('js-password')[0];
  const visibility = targetWrapper.getElementsByClassName(
    'js-creator-password-visibility',
  )[0];
  visibility.addEventListener('click', togglePasswordMask);
}

setTogglePasswordEvent('js-password-toggle-wrapper');
setTogglePasswordEvent('js-forem-owner-secret-toggle-wrapper');

const name = document.getElementsByClassName('js-creator-signup-name')[0];
name.addEventListener('input', setDefaultUsername);

const editUsername = document.getElementsByClassName(
  'js-creator-edit-username',
)[0];
editUsername.addEventListener('click', showUsernameField);
