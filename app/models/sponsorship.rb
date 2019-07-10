class Sponsorship < ApplicationRecord
  LEVELS = %w[gold silver bronze tag media devrel].freeze
  LEVELS_WITH_EXPIRATION = %w[gold silver bronze].freeze
  STATUSES = %w[none pending live].freeze
  # media has no fixed amount of credits
  CREDITS = {
    gold: 6_000,
    silver: 500,
    bronze: 100,
    tag: 300,
    devrel: 500
  }.with_indifferent_access.freeze

  belongs_to :user
  belongs_to :organization, inverse_of: :sponsorships
  belongs_to :sponsorable, polymorphic: true, optional: true

  validates :user, :organization, :featured_number, presence: true
  validates :level, inclusion: { in: LEVELS }
  validates :status, inclusion: { in: STATUSES }
  validates :url, url: { allow_blank: true, no_local: true, schemes: %w[http https] }

  scope :gold, -> { where(level: :gold) }
  scope :silver, -> { where(level: :silver) }
  scope :bronze, -> { where(level: :bronze) }
  scope :tag, -> { where(level: :tag) }
  scope :media, -> { where(level: :media) }
  scope :devrel, -> { where(level: :devrel) }
end
