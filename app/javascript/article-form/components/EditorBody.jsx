import { h, render } from 'preact';
import PropTypes from 'prop-types';
import Textarea from 'preact-textarea-autosize';
import { useEffect, useRef, useState } from 'preact/hooks';
import { Toolbar } from './Toolbar';
import { handleImagePasted } from './pasteImageHelpers';
import {
  handleImageDrop,
  handleImageFailure,
  onDragOver,
  onDragExit,
} from './dragAndDropHelpers';
import { usePasteImage } from '@utilities/pasteImage';
import { useDragAndDrop } from '@utilities/dragAndDrop';

function handleImageSuccess(textAreaRef) {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links, image } = response;
    const altText = image[0]
      ? image[0].name.replace(/\.[^.]+$/, '')
      : 'alt text';
    const markdownImageLink = `![${altText}](${links[0]})\n`;
    const { selectionStart, selectionEnd, value } = editableBodyElement;
    const before = value.substring(0, selectionStart);
    const after = value.substring(selectionEnd, value.length);

    editableBodyElement.value = `${before + markdownImageLink} ${after}`;
    editableBodyElement.selectionStart =
      selectionStart + markdownImageLink.length;
    editableBodyElement.selectionEnd = editableBodyElement.selectionStart;

    // Dispatching a new event so that linkstate, https://github.com/developit/linkstate,
    // the function used to create the onChange prop gets called correctly.
    editableBodyElement.dispatchEvent(new Event('input'));
  };
}

export const EditorBody = ({
  onChange,
  defaultValue,
  switchHelpContext,
  version,
}) => {
  const textAreaRef = useRef(null);
  const uninitializedTextAreaRef = useRef(null);
  const containerRef = useRef(null);
  const [textAreaInitialized, setTextAreaInitialized] = useState(false);

  const { setElement } = useDragAndDrop({
    onDrop: handleImageDrop(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
    onDragOver,
    onDragExit,
  });

  const setPasteElement = usePasteImage({
    onPaste: handleImagePasted(
      handleImageSuccess(textAreaRef),
      handleImageFailure,
    ),
  });

  useEffect(() => {
    if (textAreaRef.current && textAreaInitialized) {
      setElement(textAreaRef.current);
      setPasteElement(textAreaRef.current);
    }
  }, [setElement, setPasteElement, textAreaInitialized]);

  const initializeEnhancedTextArea = async () => {
    if (textAreaInitialized) {
      return;
    }

    const [
      { MentionAutocompleteTextArea },
      { fetchSearch },
    ] = await Promise.all([
      import('@crayons/MentionAutocompleteTextArea'),
      import('@utilities/search'),
    ]);

    render(
      <MentionAutocompleteTextArea
        ref={textAreaRef}
        replaceElement={uninitializedTextAreaRef.current.base}
        fetchSuggestions={(username) => fetchSearch('usernames', { username })}
        events={{
          onChange,
          onFocus: switchHelpContext,
        }}
      />,
      containerRef.current,
      uninitializedTextAreaRef.current.base,
    );

    setTextAreaInitialized(true);
  };

  return (
    <div
      ref={containerRef}
      data-testid="article-form__body"
      className="crayons-article-form__body drop-area text-padding"
    >
      <Toolbar version={version} />
      {textAreaInitialized ? null : (
        <Textarea
          className="crayons-textfield crayons-textfield--ghost crayons-article-form__body__field ff-monospace fs-l"
          id="article_body_markdown"
          aria-label="Post Content"
          placeholder="Write your post content here..."
          value={defaultValue}
          onInput={onChange}
          onFocus={(_event) => {
            initializeEnhancedTextArea();
            switchHelpContext(_event);
          }}
          name="body_markdown"
          ref={uninitializedTextAreaRef}
        />
      )}
    </div>
  );
};

EditorBody.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  version: PropTypes.string.isRequired,
};

EditorBody.displayName = 'EditorBody';
