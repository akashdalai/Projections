/* global sendHapticMessage, showLoginModal, showModalAfterError */

// Set reaction count to correct number
function setReactionCount(reactionName, newCount) {
  var reactionButtons = document.getElementById(
    'reaction-butt-' + reactionName,
  ).classList;
  var reactionButtonCounter = document.getElementById(
    'reaction-number-' + reactionName,
  );
  var reactionEngagementCounter = document.getElementById(
    'reaction_engagement_' + reactionName + '_count',
  );
  if (newCount > 0) {
    reactionButtons.add('activated');
    reactionButtonCounter.textContent = newCount;
    if (reactionEngagementCounter) {
      reactionEngagementCounter.parentElement.classList.remove('hidden');
      reactionEngagementCounter.textContent = newCount;
    }
  } else {
    reactionButtons.remove('activated');
    reactionButtonCounter.textContent = '0';
    if (reactionEngagementCounter) {
      reactionEngagementCounter.parentElement.classList.add('hidden');
    }
  }
}

function showUserReaction(reactionName, animatedClass, wasToggling) {
  const reactionButton = document.getElementById(
    'reaction-butt-' + reactionName,
  );
  reactionButton.classList.add('user-activated', animatedClass);
  reactionButton.setAttribute('aria-pressed', 'true');
  const reactionDrawerButton = document.getElementById(
    "reaction-drawer-trigger"
  );

  if (reactionDrawerButton && reactionName !== "readinglist") {
    reactionDrawerButton.classList.add('user-activated', 'user-animated');
  }

  if (wasToggling) {
    const activeIcon = reactionButton.querySelector(
      '.crayons-reaction__icon--active svg',
    );

    if (activeIcon) {
      const activeDrawerIcon = reactionDrawerButton
        .querySelector(".crayons-reaction__icon--active svg");
      reactionDrawerButton.originalIcon = activeDrawerIcon.outerHTML;
      activeDrawerIcon.outerHTML = activeIcon.outerHTML;

      setTimeout(function () {
        console.log("A little while later")
        document
          .getElementById('reaction-drawer-trigger')
          .querySelector(".crayons-reaction__icon--active svg").outerHTML =
          reactionDrawerButton.originalIcon;
      }, 1500);
    }
  }
}

function hideUserReaction(reactionName) {
  const reactionButton = document.getElementById(
    'reaction-butt-' + reactionName,
  );
  reactionButton.classList.remove('user-activated', 'user-animated');
  reactionButton.setAttribute('aria-pressed', 'false');
}

function hasUserReacted(reactionName) {
  return document
    .getElementById('reaction-butt-' + reactionName)
    .classList.contains('user-activated');
}

function getNumReactions(reactionName) {
  const reactionEl = document.getElementById('reaction-number-' + reactionName);
  if (!reactionEl || reactionEl.textContent === '') {
    return 0;
  }

  return parseInt(reactionEl.textContent, 10);
}

function reactToArticle(articleId, reaction) {
  var reactionTotalCount = document.getElementById('reaction_total_count');

  // Visually toggle the reaction
  function toggleReaction() {
    var currentNum = getNumReactions(reaction);
    if (hasUserReacted(reaction)) {
      hideUserReaction(reaction);
      setReactionCount(reaction, currentNum - 1);
      if (reactionTotalCount) {
        reactionTotalCount.innerText = Number(reactionTotalCount.innerText) - 1;
      }
    } else {
      showUserReaction(reaction, 'user-animated', 'toggleReaction');
      setReactionCount(reaction, currentNum + 1);
      if (reactionTotalCount) {
        reactionTotalCount.innerText = Number(reactionTotalCount.innerText) + 1;
      }
    }
  }
  var userStatus = document.body.getAttribute('data-user-status');
  sendHapticMessage('medium');
  if (userStatus === 'logged-out') {
    showLoginModal({
      referring_source: 'reactions_toolbar',
      trigger: reaction,
    });
    return;
  }
  toggleReaction();
  document.getElementById('reaction-butt-' + reaction).disabled = true;

  function createFormdata() {
    /*
     * What's not shown here is that "authenticity_token" is included in this formData.
     * The logic can be seen in sendFetch.js.
     */
    var formData = new FormData();
    formData.append('reactable_type', 'Article');
    formData.append('reactable_id', articleId);
    formData.append('category', reaction);
    return formData;
  }

  getCsrfToken()
    .then(sendFetch('reaction-creation', createFormdata()))
    .then((response) => {
      if (response.status === 200) {
        return response.json().then(() => {
          document.getElementById('reaction-butt-' + reaction).disabled = false;
        });
      } else {
        toggleReaction();
        document.getElementById('reaction-butt-' + reaction).disabled = false;
        showModalAfterError({
          response,
          element: 'reaction',
          action_ing: 'updating',
          action_past: 'updated',
        });
        return undefined;
      }
    })
    .catch((error) => {
      toggleReaction();
      document.getElementById('reaction-butt-' + reaction).disabled = false;
    });
}

function setCollectionFunctionality() {
  if (document.getElementById('collection-link-inbetween')) {
    var inbetweenLinks = document.getElementsByClassName(
      'series-switcher__link--inbetween',
    );
    var inbetweenLinksLength = inbetweenLinks.length;
    for (var i = 0; i < inbetweenLinks.length; i += 1) {
      inbetweenLinks[i].onclick = (e) => {
        e.preventDefault();
        var els = document.getElementsByClassName(
          'series-switcher__link--hidden',
        );
        var elsLength = els.length;
        for (var j = 0; j < elsLength; j += 1) {
          els[0].classList.remove('series-switcher__link--hidden');
        }
        for (var k = 0; k < inbetweenLinksLength; k += 1) {
          inbetweenLinks[0].className = 'series-switcher__link--hidden';
        }
      };
    }
  }
}

function requestReactionCounts(articleId) {
  var ajaxReq;
  ajaxReq = new XMLHttpRequest();
  ajaxReq.onreadystatechange = () => {
    if (ajaxReq.readyState === XMLHttpRequest.DONE) {
      var json = JSON.parse(ajaxReq.response);
      json.article_reaction_counts.forEach((reaction) => {
        setReactionCount(reaction.category, reaction.count);
      });
      json.reactions.forEach((reaction) => {
        if (document.getElementById('reaction-butt-' + reaction.category)) {
          showUserReaction(reaction.category, 'not-user-animated');
        }
      });
    }
  };
  ajaxReq.open('GET', '/reactions?article_id=' + articleId, true);
  ajaxReq.send();
}

function initializeArticleReactions() {
  setCollectionFunctionality();

  setTimeout(() => {
    var reactionButts = document.getElementsByClassName('crayons-reaction');

    // we wait for the article to appear,
    // we also check that reaction buttons are there as draft articles don't have them
    if (document.getElementById('article-body') && reactionButts.length > 0) {
      var articleId = document.getElementById('article-body').dataset.articleId;

      requestReactionCounts(articleId);

      for (var i = 0; i < reactionButts.length; i += 1) {
        if (reactionButts[i].classList.contains('pseudo-reaction')) {
          continue;
        }
        reactionButts[i].onclick = function addReactionOnClick(e) {
          reactToArticle(articleId, this.dataset.category);
        };
      }
    }

    var jumpToCommentsButt = document.getElementById('reaction-butt-comment');
    var commentsSection = document.getElementById('comments');
    if (
      document.getElementById('article-body') &&
      commentsSection &&
      jumpToCommentsButt
    ) {
      jumpToCommentsButt.onclick = function jumpToComments(e) {
        commentsSection.scrollIntoView({ behavior: 'smooth' });
      };
    }
  }, 3);
}
