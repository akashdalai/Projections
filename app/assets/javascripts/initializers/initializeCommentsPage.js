function initializeCommentsPage() {
  if (document.getElementById('comments-container')) {
    var commentableId = document.getElementById('comments-container').dataset.commentableId;
    var commentableType = document.getElementById('comments-container').dataset.commentableType;
    commentableIdList = commentableId.split(",");
    var f = (function() {
      for (var i = 0; i < commentableIdList.length; i++) {
        (function(i){
          var ajaxReq;
          if (window.XMLHttpRequest) {
            ajaxReq = new XMLHttpRequest();
          } else {
            ajaxReq = new ActiveXObject('Microsoft.XMLHTTP');
          }
          ajaxReq.onreadystatechange = function () {
            if (ajaxReq.readyState === XMLHttpRequest.DONE) {
              var responseObj = JSON.parse(ajaxReq.response);
              var reactions = responseObj.reactions;
              var allNodes = document.getElementsByClassName('single-comment-node');
              var publicReactionCounts = responseObj.public_reaction_counts;
              for (var i = 0; i < reactions.length; i++) {
                var buttForComment = document.getElementById('button-for-comment-' + reactions[i].reactable_id);
                if (buttForComment) {
                  buttForComment.classList.add('reacted');
                }
              }
              for (var i = 0; i < publicReactionCounts.length; i++) {
                var buttForComment = document.getElementById('button-for-comment-' + publicReactionCounts[i].id);
                if (buttForComment) {
                  if (publicReactionCounts[i].count > 0) {
                    if (!document.getElementById('reactions-count-' + publicReactionCounts[i].id)) {
                      buttForComment.innerHTML = buttForComment.innerHTML + "<span class='reactions-count' id='reactions-count-" + publicReactionCounts[i].id + "'>" + publicReactionCounts[i].count + '</span>';
                    } else {
                      document.getElementById('reactions-count-' + publicReactionCounts[i].id).innerHTML = publicReactionCounts[i].count;
                    }
                  }
                }
              }

              for (var i = 0; i < allNodes.length; i++) {
                if (allNodes[i].dataset.commentAuthorId == responseObj.current_user.id) {
                  allNodes[i].dataset.currentUserComment = "true";
                  var userActionsEl = allNodes[i].children[0].children[2].children[0];
                  var buttEl = document.getElementById('button-for-comment-' + allNodes[i].dataset.commentId);
                  if (userActionsEl && buttEl) {
                    userActionsEl.className = 'current-user-actions';
                    userActionsEl.innerHTML = '<a data-no-instant href="' + userActionsEl.parentNode.dataset.path + '/delete_confirm" class="edit-butt">Delete</a>\
                                                <a href="' + userActionsEl.parentNode.dataset.path + '/edit">Edit</a>'
                    userActionsEl.style.display = 'inline-block';
                    document.getElementById('button-for-comment-' + allNodes[i].dataset.commentId).classList.add('reacted');
                  }
                }
              }
            }
          };

          ajaxReq.open("GET", "/reactions?commentable_id=" + commentableIdList[i] + "&commentable_type=" + commentableType, true);
          ajaxReq.send();
        })(i);
      }
    })();

    var butts = document.getElementsByClassName('reaction-button');
    for (var i = 0; i < butts.length; i++) {
      var butt = butts[i];
      butt.onclick = function (event) {
        var thisButt = this;
        event.preventDefault();
        sendHapticMessage('medium');
        var userStatus = document.body.getAttribute('data-user-status');
        if (userStatus === 'logged-out') {
          showModal('react-to-comment');
          return;
        }

        thisButt.classList.add('reacted');
        thisButt.disabled = true;

        function successCb(response) {
          var reactionCountSpan = thisButt.children[2];
          if (response.result === 'create') {
            thisButt.classList.add('reacted');
            if (reactionCountSpan) {
              reactionCountSpan.innerHTML = parseInt(reactionCountSpan.innerHTML) + 1;
            }
          } else {
            thisButt.classList.remove('reacted');
            if (reactionCountSpan) {
              reactionCountSpan.innerHTML = parseInt(reactionCountSpan.innerHTML) - 1;
            }
          }
        }
        var formData = new FormData();
        formData.append('reactable_type', 'Comment');
        formData.append('reactable_id', thisButt.dataset.commentId);
        getCsrfToken()
          .then(sendFetch('reaction-creation', formData))
          .then(function (response) {
            thisButt.disabled = false;
            if (response.status === 200) {
              response.json().then(successCb);
            }
          });
      };
    }
    var replyButts = document.getElementsByClassName('toggle-reply-form');
    for (var i = 0; i < replyButts.length; i++) {
      var butt = replyButts[i];
      butt.onclick = function (event) {
        event.preventDefault();
        if (event.target.classList.contains("thread-indication")) {
          return false;
        } else {
          var userStatus = document.body.getAttribute('data-user-status');
          if (userStatus == 'logged-out') {
            showModal('reply-to-comment');
            return;
          }
          var actionNode = event.target.parentNode;
          var parentId = actionNode.dataset.commentId;
          var waitingOnCSRF = setInterval(function () {
            var metaTag = document.querySelector("meta[name='csrf-token']");
            if (metaTag) {
              clearInterval(waitingOnCSRF);
              commentWrapper = event.target.closest('.inner-comment');
              commentWrapper.classList.add("replying");
              commentWrapper.innerHTML += buildCommentFormHTML(commentableId, commentableType, parentId);
              initializeCommentsPage();
              
              setTimeout(function () {
                commentWrapper.getElementsByTagName('textarea')[0].focus();
              }, 30);
            }
          }, 1);
        };
        return false;
      }
    }
    var editButts = document.getElementsByClassName('edit-butt');
    for (var i = 0; i < editButts.length; i++) {
      var butt = editButts[i];
      butt.onclick = function () {
        // event.preventDefault();
        // alert("edit clicked!")
      };
    }
    if (document.getElementById('new_comment')) {
      document.getElementById('new_comment').addEventListener('submit', handleCommentSubmit);
    }
  }
  listenForDetailsToggle();
  const user = userData();
  addCommentDropdownFunctionality(user);
}

function addCommentDropdownFunctionality(user) {
  if (document.getElementById('comments-container')) {
    var commentDropdowns = document.getElementsByClassName('comment-dropdown-shell');

    for (let i = 0; i < commentDropdowns.length; i += 1) {
      let shell = commentDropdowns[i];
      let shellData = shell.dataset
      let hideHTML = '';
      let hideAction = '';
      if (user && user.id === shellData.commentableUserId) {
        if (shellData.hidden === 'false') {
          hideAction = 'hide'
        } else {
          hideAction = 'unhide'
        }  
        hideHTML = `<a href="#" class="crayons-link crayons-link--block hide-comment" data-hide-type="${hideAction}" data-comment-id="${shellData.commentId}">${capitalizeFirstLetter(hideAction)}</a>`
      }
      shell.innerHTML = `<div class="crayons-dropdown p-1 right-1 left-1 s:right-0 s:left-auto fs-base">
        <a href="${shellData.commentPath}" class="crayons-link crayons-link--block">Permalink</a>
        ${user && user.id === shellData.commentUserId ?
          `<a href="${shellData.commentPath}/settings" rel="nofollow" class="crayons-link crayons-link--block" data-no-instant>Settings</a>` : ''}
        ${hideHTML}
        </span>
        <span class="mod-actions hidden mod-actions-comment-button" data-path="${shellData.commentPath}/mod"></span>
        <span class="report-abuse-link-wrapper" data-path="/report-abuse?url=${window.location.origin + shellData.commentPath}"></span>
      </div>`
    }
  }
}


function replaceActionButts(el) {
  var loggedInActionButts = "";
  var wrapper = el.getElementsByClassName("actions")[0]
  if (el.dataset.currentUserComment == "true") {
    loggedInActionButts = '<a data-no-instant href="' + el.parentNode.parentNode.dataset.path + '/delete_confirm" class="edit-butt">Delete</a>\
                            <a href="' + el.parentNode.parentNode.dataset.path + '/edit">Edit</a>'
  }
  wrapper.innerHTML = '<span class="current-user-actions">' + loggedInActionButts + '</span><a href="#" class="toggle-reply-form">Reply</a>';
}

function handleCommentSubmit(event) {
  event.preventDefault();
  var form = event.target;
  form.classList.add('submitting');
  var textarea = form.getElementsByClassName('comment-textarea')[0];
  if (textarea) {
    textarea.style.height = null;
    textarea.blur();
  }
  var parentComment = document.getElementById("comment-node-" + event.target.dataset.commentId);

  var body = JSON.stringify({
    comment: {
      body_markdown: form.getElementsByTagName("textarea")[0].value,
      commentable_id: form.querySelector("#comment_commentable_id").value,
      commentable_type: form.querySelector("#comment_commentable_type").value,
      parent_id: form.querySelector("#comment_parent_id") ? form.querySelector("#comment_parent_id").value : null,
    }
  });

  getCsrfToken()
    .then(sendFetch('comment-creation', body))
    .then(function (response) {
      if (response.status === 200) {
        response.json().then(function (newComment) {
          var newNode = document.createElement('div');
          newNode.innerHTML = buildCommentHTML(newComment);
          var docBody = document.body

          var userData = JSON.parse(docBody.getAttribute('data-user'))
          userData.checked_code_of_conduct = true;

          docBody.dataset.user = JSON.stringify(userData);

          var checkbox = form.getElementsByClassName('code-of-conduct')[0]
          if (checkbox) {
            checkbox.innerHTML = ""
          }

          var mainCommentsForm = document.getElementById("new_comment");
          if (parentComment) {
            handleFormClose(event);
            if (newComment.depth > 2) {
              parentComment.getElementsByClassName("toggle-reply-form")[0].innerHTML = ""
            }
            var actionsNode = parentComment.getElementsByClassName("inner-comment")[0];
            actionsNode.parentNode.insertBefore(newNode, actionsNode.nextSibling);
          }

          else if (mainCommentsForm) {
            var mainCommentsForm = document.getElementById("new_comment");
            mainCommentsForm.classList.remove("submitting");
            const textArea = form.querySelector(".comment-textarea");
            textArea.closest('.comment-form').classList.remove('comment-form--initiated');
            textArea.value = newComment.comment_template || "";
            var preview = document.getElementById("preview-div");
            preview.classList.add("preview-toggle");
            preview.innerHTML = "";
            var container = document.getElementById("comment-trees-container");
            container.insertBefore(newNode, container.firstChild);
          }
          else if (document.getElementById("notifications-container")) {
            var newDiv = document.createElement("span")
            newDiv.innerHTML = '<div class="crayons-notice align-center p-2 m-2 crayons-notice--success reply-sent-notice reply-sent-notice">Reply sent — <a href="' + newComment.url + '">Check it out</a></div>'
            form.replaceWith(newDiv);
          }
          else {
            window.location.replace(newComment.url)
          }
          initializeCommentsPage();
          initializeCommentDate();
          initializeCommentDropdown();
          activateRunkitTags();
        })
      } else {
        response.json().then(function parseError(errorReponse) {
          form.classList.remove('submitting');
          showRateLimitModal('made a comment', 'making another comment')
          return false;
        });
      }
      return false;
    });
  return false;
}

function handleFocus(event) {
  handleButtonsActivation(event);
  var userStatus = document.body.getAttribute('data-user-status');
  var area = event.target;
  if (userStatus == 'logged-out') {
    event.preventDefault();
    showModal('reply-to-comment');
    area.blur();
    setTimeout(function () {
      area.blur();
      showModal('reply-to-comment');
    }, 100);
  } else {
    var form = event.target.closest(".comment-form");
    form.classList.add("comment-form--initiated");
    handleSizeChange(event);
  }
}

function handleKeyUp(event) {
  handleSizeChange(event);
  handleButtonsActivation(event);
}

// Handler for when Ctrl+Enter OR Command+Enter is pressed
function handleSubmit(event) {
  // Get user details and extract code of conduct & comment count
  var user = userData();
  if (!user) {
    return;
  }

  var codeOfConduct = user.checked_code_of_conduct;
  if (codeOfConduct && event.target.value.trim() !== '') {
    event.target.closest('form').querySelector('button[type="submit"]').click();
  }
}

// Handler when Ctrl+B/I OR Command+B/I is pressed
function handleBoldAndItalic(event) {
  var textArea = event.target;

  var selection = textArea.value.substring(textArea.selectionStart, textArea.selectionEnd);
  var selectionStart = textArea.selectionStart;
  var surroundingStr = event.keyCode === KEY_CODE_B ? "**" : "_";

  replaceSelectedText(textArea, `${surroundingStr}${selection}${surroundingStr}`);

  var selectionStartWithOffset = selectionStart + surroundingStr.length;
  textArea.setSelectionRange(selectionStartWithOffset, selectionStartWithOffset + selection.length);
}

// Handler when Ctrl+K OR Command+K is pressed
function handleLink(event) {
  var textArea = event.target;

  var selection = textArea.value.substring(textArea.selectionStart, textArea.selectionEnd);
  var selectionStart = textArea.selectionStart;

  replaceSelectedText(textArea, `[${selection}](url)`);

  // start position + length of selection + [](
  var startOffset = selectionStart + selection.length + 3;

  // start offset + 'url'.length
  var endOffset = startOffset + 3;

  textArea.setSelectionRange(startOffset, endOffset);
}

function replaceSelectedText(textArea, text) {
  // Chrome and other modern browsers (except FF and IE 8,9,10,11)
  if (document.execCommand('insertText', false, text)) {
  }
  // Firefox (non-standard method)
  else if (typeof textArea.setRangeText === "function") {
    textArea.setRangeText(text);
  }

  /*
    Disabling IE 8-11 for now as there's no easy way to verify all this
    We can revisit this if it's really needed and find a jQuery plugin to use

    // IE 8-10
    else if(document.selection) {
      const ieRange = document.selection.createRange();
      ieRange.text = text;

      // Move cursor after the inserted text
      ieRange.collapse(false); // to the end
      ieRange.select();
    }
    else {
      // Does not support IE 11 yet
    }
  */
}

var KEY_CODE_B = 66;
var KEY_CODE_I = 73;
var KEY_CODE_K = 75;
var ENTER_KEY_CODE = 13;

function handleKeyDown(event) {
  if (event.ctrlKey || event.metaKey) {
    switch (event.keyCode) {
      case KEY_CODE_B:
        event.preventDefault();
        handleBoldAndItalic(event);
        break;
      case KEY_CODE_I:
        event.preventDefault();
        handleBoldAndItalic(event);
        break;
      case KEY_CODE_K:
        event.preventDefault();
        handleLink(event);
        break;
      case ENTER_KEY_CODE:
        event.preventDefault();
        handleSubmit(event);
        break;
      default:
        break;
    }
  }
}

function handleFormClose(event) {
  event.target.closest('.inner-comment').classList.remove("replying");
  event.target.closest('.comment-form').remove();
  initializeCommentsPage();
}

function handleSizeChange(event) {
  var textarea = event.target;
  var oldHeight = parseInt(textarea.style.height.replace('px',''));
  textarea.style.height = textarea.scrollHeight + (textarea.scrollHeight > oldHeight ? 15 : 0) + "px";
}

function handleButtonsActivation(event) {
  var textarea = event.target;
  var buttons = textarea.closest('.comment-form').querySelectorAll('.js-btn-enable');
  buttons.forEach(function(button) {
    if( textarea.value.length > 0) {
      button.disabled = false;
    } else {
      button.disabled = true;
    }
  });
}

function validateField(event) {
  var textarea = event.target.closest('.comment-form').querySelector('.comment-textarea');
  if (textarea) {
    var commentField = textarea.value;
    if (commentField == '') {
      event.preventDefault();
    }
  }
}

function handleChange(event) {
  handleButtonsActivation(event);
}

function generateUploadFormdata(image) {
  var token = document.querySelector("meta[name='csrf-token']").content;
  var formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('image', image[0]);
  return formData;
}

function handleImageUpload(event, randomIdNumber) {
  var commentableId = document.getElementById('comments-container').dataset.commentableId;
  event.preventDefault();
  document.getElementById('image-upload-' + randomIdNumber).click();
  document.getElementById('image-upload-' + randomIdNumber).onchange = function (e) {
    var image = document.getElementById('image-upload-' + randomIdNumber).files;
    if (image.length > 0) {
      document.getElementById("image-upload-file-label-" + randomIdNumber).style.color = '#888888';
      document.getElementById("image-upload-file-label-" + randomIdNumber).innerHTML = "Uploading...";
      document.getElementById("image-upload-submit-" + randomIdNumber).value = "uploading";
      setTimeout(function () {
        document.getElementById("image-upload-submit-" + randomIdNumber).click(function () { });
      }, 50)
    }
  }

  document.getElementById("image-upload-submit-" + randomIdNumber).onclick = function (e) {
    e.preventDefault();
    var image = document.getElementById('image-upload-' + randomIdNumber).files;
    if (image.length > 0) {
      getCsrfToken()
        .then(sendFetch("image-upload", generateUploadFormdata(image)))
        .then(function (response) {
          if (response.status === 200) {
            response.json().then(
              function uploadImageCb(json) {
                var address = document.getElementById("uploaded-image-" + randomIdNumber);
                var button = document.getElementById("image-upload-button-" + randomIdNumber);
                var messageContainer = document.getElementById("image-upload-file-label-" + randomIdNumber)
                // button.style.display = "none";
                messageContainer.style.display = "none";
                address.value = json.links[0];
                address.classList.remove("hidden");;
                address.select();

                var uploadedMessage = 'Uploaded! Paste into editor';
                messageContainer.innerHTML = uploadedMessage;
                messageContainer.style.color = '#00c673';
                messageContainer.style.position = "relative";
                messageContainer.style.top = "5px";
              }
            );
          } else {
            response.json().then(function(responseBody) {
              var errorMessage = responseBody.error || 'Invalid file!';
              document.getElementById("image-upload-file-label-" + randomIdNumber).innerHTML = errorMessage;
              document.getElementById("image-upload-file-label-" + randomIdNumber).style.color = '#e05252';
              document.getElementById("image-upload-submit-" + randomIdNumber).style.display = 'none';
            });
          }
        })
        .catch(function (err) {
          // there's currently no error handling
        })
    }
  }
}

function listenForDetailsToggle() {
  var detailItems = document.getElementsByTagName("DETAILS");
  for (var i = 0; i < detailItems.length; i++) {
    detailItems[i].addEventListener("toggle", event => {
      var item = event.target
      var itemSummaryContent = item.getElementsByTagName("SPAN")[0]
      var usernames = item.getElementsByClassName("comment-username")
      var number = "";
      if (usernames.length > 1) {
        number = " + " + (usernames.length - 1) + " replies"
      }
      var itemUsername = usernames[0].textContent + number
      if (item.open) {
        itemSummaryContent.innerHTML = "&nbsp;"
      } else {
        itemSummaryContent.innerHTML = itemUsername;
      }
      item.getElementsByTagName("SUMMARY")[0].blur();
    });
  }
}
