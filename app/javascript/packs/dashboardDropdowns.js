import { initializeDropdown } from '@utilities/dropdownUtils';

function getFormValues(form) {
  const articleId = form.action.match(/\/(\d+)$/)[1];
  const inputs = form.getElementsByTagName('input');
  const formData = { id: articleId, article: {} };

  for (let i = 0; i < inputs.length; i += 1) {
    const input = inputs[i];
    const name = input.getAttribute('name');
    const value = input.getAttribute('value');

    if (name.match(/\[(.*)\]/)) {
      const key = name.match(/\[(.*)\]$/)[1];
      formData.article[key] = value;
    } else {
      formData[name] = value;
    }
  }

  return formData;
}

function toggleArchived(article, needsArchived) {
  if (needsArchived === 'true') {
    article.classList.add('story-archived', 'hidden');
  } else {
    article.classList.remove('story-archived');
  }
}

function toggleNotifications(submit, action) {
  if (action === 'Mute Notifications') {
    submit.setAttribute('value', 'Receive Notifications');
  } else {
    submit.setAttribute('value', 'Mute Notifications');
  }
}

function onXhrSuccess(form, article, values) {
  if (values.article.archived) {
    toggleArchived(article, values.article.archived);
  } else {
    const submit = form.querySelector('[type="submit"]');
    const submitValue = submit.getAttribute('value');

    toggleNotifications(submit, submitValue);
  }
}

const handleFormSubmit = (e) => {
  e.preventDefault();
  e.stopPropagation();

  const { target: form } = e;
  const values = getFormValues(form);
  const data = JSON.stringify(values);

  const formData = new FormData(form);
  const method = formData.get('_method') || 'post';

  const xhr = new XMLHttpRequest();
  xhr.open(method.toUpperCase(), form.action);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(data);

  xhr.onload = function onload() {
    const article = form.closest('.js-dashboard-story');

    if (xhr.status === 200) {
      onXhrSuccess(form, article, values);
      const message =
        values.commit === 'Mute Notifications'
          ? 'Notifications Muted'
          : 'Notifications Restored';
      article.getElementsByClassName(
        'js-dashboard-story-details',
      )[0].innerHTML = message;
    } else {
      article.getElementsByClassName(
        'js-dashboard-story-details',
      )[0].innerHTML = 'Failed to update article.';
    }
  };
};

const initializeArchiveToggleFormSubmit = () => {
  const archiveToggleForms = document.querySelectorAll(
    '.js-ellipsis-menu-dropdown .js-archive-toggle',
  );

  archiveToggleForms.forEach((form) => {
    form.addEventListener('submit', handleFormSubmit);
  });
};

const initializeEllipsisMenuToggle = () => {
  const dropdownTriggerButtons = document.querySelectorAll(
    'button[id^=ellipsis-menu-trigger-]',
  );

  dropdownTriggerButtons.forEach((triggerButton) => {
    if (triggerButton.dataset.initialized !== 'true') {
      const dropdownContentId = triggerButton.getAttribute('aria-controls');
      const { closeDropdown } = initializeDropdown({
        triggerElementId: triggerButton.id,
        dropdownContentId,
      });

      // Close dropdown after toggling the archive status
      document
        .getElementById(dropdownContentId)
        ?.querySelectorAll('.js-archive-toggle')
        ?.forEach((menuElement) => {
          menuElement.addEventListener('click', closeDropdown);
        });
      triggerButton.dataset.initialized = 'true';
    }
  });
};

initializeEllipsisMenuToggle();
initializeArchiveToggleFormSubmit();
