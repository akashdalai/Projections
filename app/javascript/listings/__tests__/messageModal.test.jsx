import { h } from 'preact';
import { deep } from 'preact-render-spy';
import MessageModal from '../elements/messageModal';

const defaultListing = {
  id: 22,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-perspiciatis-5hk7',
  title: 'Illo iure quos perspiciatis.',
  tags: ['go', 'git'],
  author: {
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const defaultProps = {
  currentUserId: 1,
  message: 'Something',
  onChangeDraftingMessage: () => {
    return 'onChangeDraftingMessage';
  },
  onSubmit: () => {
    return 'onSubmit;';
  },
};

const renderMessageModal = (listing) =>
  deep(<MessageModal {...defaultProps} listining={listing} />);

describe('<MessageModal />', () => {
  describe('When the current user is the author', () => {
    const listingWithCurrentUserId = {
      ...defaultListing,
      user_id: 1,
    };
    const context = renderMessageModal(listingWithCurrentUserId);
    const idFromPersonalMessageContact = 'personal-contact-message';
    const idFromPersonalMessageAboutInteractions =
      'personal-message-about-interactions';

    it('Should show the information about contact with the current user', () => {
      expect(context.find(`#${idFromPersonalMessageContact}`).text()).toEqual(
        'This is your active listing. Any member can contact you via this form.',
      );
    });

    it('Should show the personalized message about the interactions', () => {
      expect(
        context.find(`#${idFromPersonalMessageAboutInteractions}`).text(),
      ).toEqual('All private interactions must abide by the code of conduct');
    });
  });

  describe('When current user is not the author', () => {
    const listingWithDifferentCurrentUserId = {
      ...defaultListing,
      user_id: 111,
    };
    const context = renderMessageModal(listingWithDifferentCurrentUserId);
    const idFromGenericMessageContact = 'generic-contact-message';
    const idFromGenericMessageAboutInteractions =
      'generic-message-about-interactions';

    it('Should show the message to contact the author', () => {
      expect(context.find(`#${idFromGenericMessageContact}`).text()).toEqual(
        `Contact ${listingWithDifferentCurrentUserId.author.name} via DEV Connect`,
      );
    });

    it('Should show a generic message about the interactions', () => {
      expect(
        context.find(`#${idFromGenericMessageAboutInteractions}`).text(),
      ).toEqual(
        'Message must be relevant and on-topic with the listing. All private interactions must abide by the code of conduct',
      );
    });
  });
});
