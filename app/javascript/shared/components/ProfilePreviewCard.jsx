import { h } from 'preact';

export const MinimalProfilePreviewCard = ({
  triggerId,
  contentId,
  username,
  name,
  profileImage,
  userId,
}) => (
  <div class="profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:block">
    <button
      id={triggerId}
      aria-controls={contentId}
      class="profile-preview-card__trigger px-0 crayons-btn crayons-btn--ghost p-0"
      aria-label={`${username} profile details`}
    >
      {name}
    </button>

    <div
      id={contentId}
      class="profile-preview-card__content crayons-dropdown"
      style="border-top: var(--su-7) solid var(--card-color);"
      data-testid="profile-preview-card"
    >
      <div class="gap-4 grid">
        <div class="-mt-4">
          <a href={`/${username}`} class="flex">
            <span class="crayons-avatar crayons-avatar--xl mr-2 shrink-0">
              <img
                src={profileImage}
                class="crayons-avatar__image"
                alt=""
                loading="lazy"
              />
            </span>
            <span class="crayons-link crayons-subtitle-2 mt-5">{name}</span>
          </a>
        </div>
        <div class="print-hidden">
          <button
            class="crayons-btn follow-action-button whitespace-nowrap follow-user w-100"
            data-info={{
              id: userId,
              className: 'User',
              style: 'full',
            }}
          >
            Follow
          </button>
        </div>
        <span
          class="author-preview-metadata-container"
          data-author-id={userId}
        />
      </div>
    </div>
  </div>
);
