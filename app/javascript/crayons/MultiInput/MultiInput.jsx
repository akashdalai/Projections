import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { useRef, useState, useEffect } from 'preact/hooks';
// TODO: change the path to a shared component
import { DefaultSelectionTemplate } from '../MultiSelectAutocomplete/DefaultSelectionTemplate';

const KEYS = {
  ENTER: 'Enter',
  COMMA: ',',
  SPACE: ' ',
};
// TODO: think about how this may change based on
// a different usage. We will most likely want this to be passed in as a prop.
const ALLOWED_CHARS_REGEX = /([a-zA-Z0-9@.])/;

/**
 * Component allowing users to add multiple entries for a given input field that get displayed as destructive pills
 *
 * @param {Object} props
 * @param {string} props.placeholder Input placeholder text
 */

export const MultiInput = ({
  placeholder,
  SelectionTemplate = DefaultSelectionTemplate,
}) => {
  const inputRef = useRef(null);
  const [items, setItems] = useState([]);

  // TODO: possibly refactor into a reducer
  const [editValue, setEditValue] = useState(null);
  const [inputPosition, setInputPosition] = useState(null);

  useEffect(() => {
    // editValue defaults to null when component is first rendered.
    // This ensures we do not autofocus the input before the user has started interacting with the component.
    if (editValue === null) {
      return;
    }

    const { current: input } = inputRef;
    if (input && inputPosition !== null) {
      // Entering 'edit' mode
      // resizeInputToContentSize();
      input.value = editValue;
      const { length: cursorPosition } = editValue;
      input.focus();
      // this will set the cursor position at the end of the text.
      input.setSelectionRange(cursorPosition, cursorPosition);
    }
  }, [inputPosition, editValue]);

  const handleBlur = ({ target: { value } }) => {
    addItemToList(value);
    clearInput();
  };

  const handleKeyDown = (e) => {
    switch (e.key) {
      case KEYS.SPACE:
      case KEYS.ENTER:
      case KEYS.COMMA:
        e.preventDefault();
        addItemToList(e.target.value);
        clearInput();
        break;
      default:
        if (!ALLOWED_CHARS_REGEX.test(e.key)) {
          e.preventDefault();
        }
    }
  };

  const deselectItem = (clickedItem) => {
    const newArr = items.filter((item) => item !== clickedItem);
    setItems(newArr);
  };

  const addItemToList = (value) => {
    // TODO: we will want to do some validation here based on a prop
    if (value.trim().length > 0) {
      setItems([...items, value]);
    }
  };

  const clearInput = () => {
    inputRef.current.value = '';
  };

  const allSelectedItemElements = items.map((item, index) => {
    return (
      <li
        key={index}
        className="c-autocomplete--multi__selection-list-item w-max"
        style={{ order: 1 }}
      >
        <SelectionTemplate
          name={item}
          onEdit={() => enterEditState(item, index)}
          onDeselect={() => deselectItem(item)}
        />
      </li>
    );
  });

  const enterEditState = (editItem, editItemIndex) => {
    deselectItem(editItem);
    setEditValue(editItem);
    setInputPosition(editItemIndex);
  };

  return (
    <Fragment>
      <div class="c-input--multi relative">
        <div class="c-input--multi__wrapper-border crayons-textfield flex items-center cursor-text pb-9">
          <ul class="list-none flex flex-wrap w-100">
            {allSelectedItemElements}
            <li class="self-center" style="order: 3;">
              <input
                autocomplete="off"
                class="c-input--multi__input"
                type="text"
                onBlur={handleBlur}
                onKeyDown={handleKeyDown}
                placeholder={placeholder}
                ref={inputRef}
              />
            </li>
          </ul>
        </div>
      </div>
    </Fragment>
  );
};

MultiInput.propTypes = {
  placeholder: PropTypes.string,
  SelectionTemplate: PropTypes.func,
};
