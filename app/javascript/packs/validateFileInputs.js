/**
 * @file Manages logic to validate file uploads client-side. It in general,
 * the validations work by looping over input form fields with type file and
 * checking the size and format of the files upload by the user.
 */

/**
 * An object containing the top level MIME type as the key and the max file
 * size in MB for the value. To use a different value than these defaults,
 * simply add a data-max-file-mb attribute to the input form field with the
 * max file size in MB. If that attribute is found, it takes priority over these
 * defaults.
 *
 * @constant {Object.<string, number>}
 */
const MAX_FILE_SIZE_MB = Object.freeze({
  image: 2,
  video: 50,
});

/**
 * Permitted file types using the top level MIME type i.e. image for image/png.
 * To specify permitted file types, simply add a data-permitted-file-types
 * attribute to the input form field as an Array of strings specifying the top
 * level MIME types that are permitted.
 *
 * @constant {string[]}
 */
const PERMITTED_FILE_TYPES = ['video', 'image'];

/**
 * Removes any pre-existing error messages from the DOM related to file validation.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 */
function removeErrorMessages(fileInput) {
  const errorMessages = fileInput.parentNode.querySelectorAll(
    'div.file-upload-error',
  );

  errorMessages.forEach(errorMessage => {
    errorMessage.remove();
  });
}

/**
 * Adds error messages in the form of a div with red text
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {string} msg - The error message to be displayed to the user
 *
 * @returns {HTMLElement} The error element that was added to the DOM
 */
function addErrorMessage(fileInput, msg) {
  const fileInputField = fileInput;
  const error = document.createElement('div');
  error.style.color = 'red';
  error.innerHTML = msg;
  error.classList.add('file-upload-error');

  // Change this to ParentNode.append(error) once Internet Explore support is added
  fileInputField.parentNode.appendChild(error);
}

/**
 * Handles errors for files that are too large
 *
 * @external File
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/File File}
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {File} file - The file that was too large in size
 */
function handleFileSizeError(fileSizeErrorHandler, fileInput, file) {
  console.error(`File too big - ${file.name}`);
  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileSizeErrorHandler) {
    fileSizeErrorHandler();
  } else {
    addErrorMessage(fileInput, 'File size was too large, try a smaller file.');
  }
}

/**
 * Handles errors for files that are not a valid format
 *
 * @external File
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/File File}
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {File} file - The file that was an invalid type
 */
function handleFileTypeError(fileTypeErrorHandler, fileInput, file) {
  console.error(`Invalid file format - ${file.name} - ${file.type}`);

  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileTypeErrorHandler) {
    fileTypeErrorHandler();
  } else {
    addErrorMessage(fileInput, 'The file format was invalid.');
  }
}

/**
 * This is the core function to handle validations of uploaded files. It loops through all the
 * uploaded files for the given fileInput and checks the file size and file format. If a file fails
 * a validation, the error is handled.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if any files failed validations. Otherwise, returns true.
 */
function validateFileInput(fileInput) {
  let validFileInput = true;

  removeErrorMessages(fileInput);
  const files = Array.from(fileInput.files);
  const permittedFileTypes =
    fileInput.dataset.permittedFileTypes || PERMITTED_FILE_TYPES;
  const { fileSizeErrorHandler } = fileInput.dataset;
  const { fileTypeErrorHandler } = fileInput.dataset;

  let { maxFileSizeMb } = fileInput.dataset;

  for (let i = 0; i < files.length; i += 1) {
    const file = files[i];
    const fileType = file.type.split('/')[0];
    const fileSizeMb = (file.size / (1024 * 1024)).toFixed(2);
    maxFileSizeMb = Number(maxFileSizeMb || MAX_FILE_SIZE_MB[fileType]);

    const isValidFileSize = fileSizeMb <= maxFileSizeMb;

    if (maxFileSizeMb && !isValidFileSize) {
      handleFileSizeError(fileSizeErrorHandler, fileInput, file);
      validFileInput = false;
      break;
    }

    const isValidFileType = permittedFileTypes.includes(fileType);

    if (!isValidFileType) {
      handleFileTypeError(fileTypeErrorHandler, fileInput, file);
      validFileInput = false;
      break;
    }
  }

  return validFileInput;
}

/**
 * This function is designed to be exported in areas where we are doing more custom implementations
 * of file uploading using Preact. It can then be used in Preact event handlers. It loops through
 * all file input fields on the DOM and validates any attached files.
 *
 * @returns {Boolean} Returns false if any files failed validations. Otherwise, returns true.
 */
export function validateFileInputs() {
  let validFileInputs = true;
  const fileInputs = document.querySelectorAll('input[type="file"]');

  for (let i = 0; i < fileInputs.length; i += 1) {
    const fileInput = fileInputs[i];
    const validFileInput = validateFileInput(fileInput);

    if (!validFileInput) {
      validFileInputs = false;
      break;
    }
  }

  return validFileInputs;
}

// This is written so that it works automatically by just including this pack in a view
const fileInputs = document.querySelectorAll('input[type="file"]');

fileInputs.forEach(fileInput => {
  fileInput.addEventListener('change', () => {
    validateFileInput(fileInput);
  });
});
