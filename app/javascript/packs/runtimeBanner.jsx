import { h, render } from 'preact';
import { RuntimeBanner } from '../runtimeBanner';

function loadElement() {
  const container = document.getElementById('runtime-banner-container');
  if (container) {
    render(<RuntimeBanner />, container);
  }
}

function initializeBannerWhenPageIsReady() {
  setTimeout(() => {
    if (document.body.getAttribute('data-loaded') === 'true') {
      // Page hasn't initialized yet. We need to wait until the page is ready
      initializeBannerWhenPageIsReady();
    } else {
      // We're ready to initialize
      window.InstantClick.on('change', () => {
        loadElement();
      });

      loadElement();
    }
  }, 100);
}

// This pack relies on the same logic as `packs/listings` & `packs/Chat`. The
// banner lives in every page (including the main feed) and a race condition
// occurs when the page initializes for the first time or when signing out
// (no cache). Because of this we defer the initialization until the page is
// actually ready.
initializeBannerWhenPageIsReady();
