require "rails_helper"

RSpec.describe Article do
  def build_and_validate_article(*args)
    article = build(:article, *args)
    article.validate!
    article
  end

  before { allow(FeatureFlag).to receive(:enabled?).with(:consistent_rendering, any_args).and_return(true) }

  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  include_examples "#sync_reactions_count", :article
  it_behaves_like "UserSubscriptionSourceable"
  it_behaves_like "Taggable"

  describe "validations" do
    it { is_expected.to belong_to(:collection).optional }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to belong_to(:user) }

    it { is_expected.to have_one(:discussion_lock).dependent(:delete) }

    it { is_expected.to have_many(:comments).dependent(:nullify) }
    it { is_expected.to have_many(:context_notifications).dependent(:delete_all) }
    it { is_expected.to have_many(:mentions).dependent(:delete_all) }
    it { is_expected.to have_many(:notification_subscriptions).dependent(:delete_all) }
    it { is_expected.to have_many(:notifications).dependent(:delete_all) }
    it { is_expected.to have_many(:page_views).dependent(:delete_all) }
    it { is_expected.to have_many(:polls).dependent(:destroy) }
    it { is_expected.to have_many(:profile_pins).dependent(:delete_all) }
    it { is_expected.to have_many(:rating_votes).dependent(:destroy) }
    it { is_expected.to have_many(:sourced_subscribers) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:tags) }
    it { is_expected.to have_many(:user_subscriptions).dependent(:nullify) }

    it { is_expected.to validate_length_of(:body_markdown).is_at_least(0) }
    it { is_expected.to validate_length_of(:cached_tag_list).is_at_most(126) }
    it { is_expected.to validate_length_of(:title).is_at_most(128) }

    it { is_expected.to validate_presence_of(:comments_count) }
    it { is_expected.to validate_presence_of(:positive_reactions_count) }
    it { is_expected.to validate_presence_of(:previous_public_reactions_count) }
    it { is_expected.to validate_presence_of(:public_reactions_count) }
    it { is_expected.to validate_presence_of(:rating_votes_count) }
    it { is_expected.to validate_presence_of(:reactions_count) }
    it { is_expected.to validate_presence_of(:user_subscriptions_count) }
    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:user_id) }

    it { is_expected.not_to allow_value("foo").for(:main_image_background_hex_color) }

    describe "::admin_published_with" do
      it "includes mascot-published articles" do
        allow(Settings::General).to receive(:mascot_user_id).and_return(3)
        user = create(:user, id: 3)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "includes staff-user-published articles" do
        allow(Settings::Community).to receive(:staff_user_id).and_return(3)
        user = create(:user, id: 3)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "includes admin published articles" do
        user = create(:user, :admin)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(1)
      end

      it "does not include regular user published articles" do
        user = create(:user)
        create(:article, user: user, tags: "challenge")
        expect(described_class.admin_published_with("challenge").count).to eq(0)
      end
    end

    describe "#body_markdown" do
      it "is unique scoped for user_id and title", :aggregate_failures do
        art2 = build(:article, body_markdown: article.body_markdown, user: article.user, title: article.title)

        expect(art2).not_to be_valid
        expect(art2.errors_as_sentence).to match("markdown has already been taken")
      end

      # using https://unicode-table.com/en/11A15/ multibyte char
      it "is valid if its bytesize is less than 800 kilobytes" do
        article.body_markdown = "𑨕" * 204_800 # 4 bytes x 204800 = 800 kilobytes

        expect(article).to be_valid
      end

      it "is not valid if its bytesize exceeds 800 kilobytes" do
        article.body_markdown = "𑨕" * 204_801

        expect(article).not_to be_valid
        expect(article.errors_as_sentence).to match("too long")
      end
    end

    describe "#validate co_authors" do
      it "is invalid if the co_author is the same as the author" do
        article.co_author_ids = [user.id]

        expect(article).not_to be_valid
      end

      it "is invalid if there are duplicate co_authors for the same article" do
        co_author1 = create(:user)
        article.co_author_ids = [co_author1, co_author1]

        expect(article).not_to be_valid
      end

      it "is invalid if the co_author is entered as a text value rather than an integer" do
        article.co_author_ids = [user.id, "abc"]

        expect(article).not_to be_valid
      end

      it "is invalid if the co_author ID is not greater than 0" do
        article.co_author_ids = [user.id, 0]

        expect(article).not_to be_valid
      end

      it "is valid if co_author_ids is nil" do
        article.co_author_ids = nil

        expect(article).to be_valid
      end
    end

    context "when published" do
      before do
        # rubocop:disable RSpec/NamedSubject
        allow(subject).to receive(:published?).and_return(true) # rubocop:disable RSpec/SubjectStub
        # rubocop:enable RSpec/NamedSubject
      end

      it { is_expected.to validate_presence_of(:slug) }
    end

    describe "#search_id" do
      it "returns article_ID" do
        expect(article.search_id).to eq("article_#{article.id}")
      end
    end

    describe "#main_image_background_hex_color" do
      it "must have true hex for image background" do
        article.main_image_background_hex_color = "hello"
        expect(article.valid?).to be(false)
        article.main_image_background_hex_color = "#fff000"
        expect(article.valid?).to be(true)
      end
    end

    describe "#canonical_url_must_not_have_spaces" do
      let!(:article) { build(:article, user: user) }

      it "is valid without spaces" do
        valid_url = "https://www.positronx.io/angular-radio-buttons-example/"
        article.canonical_url = valid_url

        expect(article).to be_valid
      end

      it "is not valid with spaces" do
        invalid_url = "https://www.positronx.io/angular radio-buttons-example/"
        article.canonical_url = invalid_url
        message = "must not have spaces"

        expect(article).not_to be_valid
        expect(article.errors.messages[:canonical_url]).to include(message)
      end
    end

    describe "#main_image" do
      it "must have url for main image if present" do
        article.main_image = "hello"
        expect(article.valid?).to be(false)
        article.main_image = "https://image.com/image.png"
        expect(article.valid?).to be(true)
      end
    end

    describe "polls" do
      let!(:poll) { create(:poll, article: article) }

      it "does not allow the use of admin-only liquid tags for non-admins" do
        article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
        expect(article.valid?).to be(false)
      end

      it "allows admins" do
        article.user.add_role(:admin)
        article.body_markdown = "hello hey hey hey {% poll #{poll.id} %}"
        expect(article.valid?).to be(true)
      end
    end

    describe "liquid tags" do
      it "is not valid if it contains invalid liquid tags" do
        body = "{% github /thepracticaldev/dev.to %}"
        article = build(:article, body_markdown: body)
        expect(article).not_to be_valid
        expect(article.errors[:base].first).to match(/Invalid GitHub/)
      end

      it "is valid with valid liquid tags", :vcr do
        VCR.use_cassette("twitter_client_status_extended") do
          article = build_and_validate_article(with_tweet_tag: true)
          expect(article).to be_valid
        end
      end
    end

    describe "title validation" do
      it "normalizes the title to a narrow set of allowable characters" do
        article = create(:article, title: "I⠀⠀Am⠀⠀Warning⠀⠀You⠀⠀Don't⠀⠀Click!")

        expect(article.title).to eq "I Am Warning You Don't Click!"
      end

      it "allows useful emojis and extended punctuation" do
        allowed_title = "Hello! Title — Emdash⁉️ 🤖🤯🔥®™©👨‍👩🏾👦‍👦"

        article = create(:article, title: allowed_title)

        expect(article.title).to eq allowed_title
      end

      it "allows Euro symbol (€)" do
        allowed_title = "Euro code €€€"

        article = create(:article, title: allowed_title)

        expect(article.title).to eq allowed_title
      end

      it "produces a proper title" do
        test_article = build(:article, title: "An Article Title")

        test_article.validate

        expect(test_article.title).to eq("An Article Title")
      end

      it "sanitizes the title with deprecated BIDI marks" do
        test_article = build(:article, title: "\u202bThis starts with BIDI embedding\u202c\u061cALM\u200e")

        test_article.validate

        expect(test_article.title).not_to match(/\u202b/)
        expect(test_article.title).to eq("This starts with BIDI embedding\u202c\u061cALM\u200e")
      end

      it "rejects empty titles after sanitizing" do
        test_article = build(:article,
                             title: "\u061c\u200e\u200f\u202a\u202b\u202c\u202d\u202e\u2066\u2067\u2068\u2069")

        test_article.validate

        expect(test_article).not_to be_valid
        expect(test_article.errors_as_sentence).to match("Title can't be blank")
      end
    end

    describe "tag validation" do
      let(:article) { build(:article, user: user) }

      # See https://github.com/forem/forem/pull/6302
      # rubocop:disable RSpec/VerifiedDoubles
      it "does not modify the tag list if there are no adjustments" do
        allow(TagAdjustment).to receive(:where).and_return(TagAdjustment.none)
        allow(article).to receive(:tag_list).and_return(spy("tag_list"))

        article.save

        # We expect this to happen once in #evaluate_front_matter
        expect(article.tag_list).to have_received(:add).once
        expect(article.tag_list).not_to have_received(:remove)
      end
      # rubocop:enable RSpec/VerifiedDoubles
    end
  end

  context "when data is extracted from evaluation of the front matter during validation" do
    let!(:title) { "Talk About It, Justify It" }
    let!(:slug) { "talk-about-it-justify-it" }
    let!(:test_article) { build(:article, title: title) }

    before { test_article.validate }

    describe "#title" do
      it "produces a proper title" do
        expect(test_article.title).to eq(title)
      end
    end

    describe "#slug" do
      it "produces a proper slug similar to the title" do
        expect(test_article.slug).to start_with(slug)
      end
    end

    describe "#tag" do
      it "parses tags" do
        expect(test_article.tag_list.length.positive?).to be(true)
      end

      it "accepts an empty tag list and returns empty array" do
        expect(build_and_validate_article(with_tags: false).tag_list).to be_empty
      end

      it "rejects more than 4 tags" do
        five_tags = "one, two, three, four, five"
        expect(build(:article, tags: five_tags).valid?).to be(false)
      end

      it "rejects tags with length > 30" do
        tags = "'testing tag length with more than 30 chars', tag"
        expect(build(:article, tags: tags).valid?).to be(false)
      end

      it "rejects tag with non-alphanumerics" do
        expect { build(:article, tags: "c++").validate! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "always downcase tags" do
        tags = "UPPERCASE, CAPITALIZE"
        article = create(:article, tags: tags)
        expect(article.tag_list).to eq(tags.downcase.split(", "))
      end

      it "parses tags when description is empty" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: one\n---\n\n"
        expect(build_and_validate_article(body_markdown: body_markdown).tag_list).to eq(["one"])
      end
    end

    describe "#description" do
      it "creates proper description when description is present" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription: hey hey hoho\ntags: one\n---\n\n"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("hey hey hoho")
      end

      it "creates proper description when description is not present and body is present and short, with no tags" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags:\n---\n\nThis is the body yo"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("This is the body yo")
      end

      it "creates proper description when description is not present and body is present and short" do
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags: heytag\n---\n\nThis is the body yo"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to eq("This is the body yo")
      end

      it "creates proper description when description is not present and body is present and long" do
        paragraphs = Faker::Hipster.paragraph(sentence_count: 40)
        body_markdown = "---\ntitle: Title\npublished: false\ndescription:\ntags:\n---\n\n#{paragraphs}"
        expect(build_and_validate_article(body_markdown: body_markdown).description).to end_with("...")
      end
    end

    describe "#canonical_url" do
      let!(:article_with_canon_url) { build(:article, with_canonical_url: true) }

      before do
        article_with_canon_url.validate
      end

      it "parses does not assign canonical_url" do
        expect(article.canonical_url).to be_nil
      end

      it "parses canonical_url if canonical_url is present" do
        expect(article_with_canon_url.canonical_url).not_to be_nil
      end

      it "parses does not remove canonical_url" do
        initial_link = article_with_canon_url.canonical_url
        article_with_canon_url.body_markdown = build(:article).body_markdown
        article_with_canon_url.validate
        expect(article_with_canon_url.canonical_url).to eq(initial_link)
      end
    end

    describe "#reading_time" do
      it "produces a correct reading time" do
        expect(test_article.reading_time).to eq(1)
      end
    end

    describe "#processed_html" do
      it "fixes the issue with --- hr tags" do
        article = build_and_validate_article(with_hr_issue: true)
        expect(article.processed_html.include?("<hr")).to be(true)
      end
    end

    describe "#body_text" do
      it "return a sanitized version of processed_html" do
        sanitized_html = ActionView::Base.full_sanitizer.sanitize(test_article.processed_html)
        expect(test_article.body_text).to eq(sanitized_html)
      end
    end

    context "when a main_image does not already exist" do
      let!(:article_without_main_image) { build(:article, with_main_image: false) }
      let(:image) { Faker::Avatar.image }

      before { article_without_main_image.validate }

      it "can parse the main_image" do
        expect(article_without_main_image.main_image).to be_nil
      end

      it "can parse the main_image when added" do
        article_without_main_image.main_image = image
        article_without_main_image.validate

        expect(article_without_main_image.main_image).to eq(image)
      end
    end

    context "when a main_image exists" do
      # The `with_main_image` flag is the factory default, but we're being explicit here.
      let!(:article_with_main_image) { build(:article, with_main_image: true) }
      let(:image) { article_with_main_image.main_image }

      before { article_with_main_image.validate }

      it "can parse the main_image" do
        expect(article_with_main_image.main_image).to eq(image)
      end

      it "can parse the main_image when removed" do
        article_with_main_image.main_image = nil
        article_with_main_image.validate

        expect(article_with_main_image.main_image).to be_nil
      end

      it "can parse the main_image when changed" do
        expect(article_with_main_image.main_image).to eq(image)

        other_image = Faker::Avatar.image
        article_with_main_image.main_image = other_image
        article_with_main_image.validate
        expect(article_with_main_image.main_image).to eq(other_image)
      end
    end
  end

  describe "#class_name" do
    it "returns class name" do
      expect(article.class_name).to eq("Article")
    end
  end

  describe "#published_at" do
    it "does not have a published_at if not published" do
      unpublished_article = build(:article, published: false, published_at: nil)
      unpublished_article.validate # to make sure the front matter extraction happens
      expect(unpublished_article.published_at).to be_nil
    end

    it "sets the default published_at if published" do
      # published_at is set in a #evaluate_markdown before_validation callback
      article.validate
      expect(article.published_at).not_to be_nil
    end

    it "sets published_at from a valid frontmatter date" do
      date = (Date.current + 5.days).strftime("%d/%m/%Y")
      article_with_date = build(:article, with_date: true, date: date, published_at: nil)
      expect(article_with_date.valid?).to be(true)
      expect(article_with_date.published_at.strftime("%d/%m/%Y")).to eq(date)
    end

    it "sets future published_at from frontmatter" do
      published_at = (Date.current + 10.days).strftime("%d/%m/%Y %H:%M")
      body_markdown = "---\ntitle: Title\npublished: false\npublished_at: #{published_at}\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      article_with_published_at = build(:article, body_markdown: body_markdown)
      expect(article_with_published_at.valid?).to be(true)
      expect(article_with_published_at.published_at.strftime("%d/%m/%Y %H:%M")).to eq(published_at)
    end

    it "sets published_at when publishing but no published_at passed from frontmatter" do
      body_markdown = "---\ntitle: Title\npublished: true\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      article = create(:article, body_markdown: body_markdown)
      article.reload
      expect(article.published_at).to be > 10.minutes.ago
    end

    it "sets published_at when publishing from draft and no published_at passed from frontmatter" do
      body_markdown = "---\ntitle: Title\npublished: true\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      draft = create(:article, published: false, published_at: nil)
      draft.update(body_markdown: body_markdown)
      draft.reload
      expect(draft.published).to be true
      expect(draft.published_at).to be > 10.minutes.ago
    end

    it "doesn't allow past published_at when publishing on create" do
      article2 = build(:article, published_at: 10.days.ago, published: true)
      expect(article2.valid?).to be false
      expect(article2.errors[:published_at])
        .to include("only future or current published_at allowed")
    end

    it "doesn't allow recent published_at when publishing on create" do
      article2 = build(:article, published_at: 1.hour.ago, published: true)
      expect(article2.valid?).to be false
      expect(article2.errors[:published_at])
        .to include("only future or current published_at allowed")
    end

    it "allows recent published_at when publishing on create" do
      article2 = build(:article, published_at: 5.minutes.ago, published: true)
      expect(article2.valid?).to be true
    end

    it "allows removing published_at when updating a scheduled draft" do
      scheduled_draft = create(:article, published: false, published_at: 1.day.from_now)
      scheduled_draft.published_at = nil
      expect(scheduled_draft).to be_valid
    end

    context "when unpublishing" do
      let!(:published_at_was) { article.published_at }

      it "keeps published_at" do
        article.update(published: false)
        article.reload
        expect(article.published_at).to be_within(1.second).of(published_at_was)
      end

      it "keeps published_at if we try to unset it" do
        article.update(published: false, published_at: nil)
        article.reload
        expect(article.published_at).to be_within(1.second).of(published_at_was)
      end

      it "keeps published_at when unpublising a scheduled article" do
        scheduled_published_at = 1.day.from_now
        article.update_columns(published_at: scheduled_published_at)
        article.update(published: false)
        article.reload
        expect(article.published_at).to be_within(1.second).of(scheduled_published_at)
      end
    end

    context "when unpublishing a frontmatter article" do
      let(:published_at) { "2022-05-05 18:00 +0300" }
      let(:body_markdown) { "---\ntitle: Title\npublished: true\npublished_at: #{published_at}\n---\n\n" }
      let(:frontmatter_article) do
        a = create(:article, :past, past_published_at: DateTime.parse(published_at))
        # if we would set markdown on create, past_published_at would be overriden by body_markdown values
        # and the validation wouldn't pass
        a.update_columns(body_markdown: body_markdown)
        a
      end

      it "keeps published at" do
        new_body_markdown = "---\ntitle: Title\npublished: false\n---\n\n"
        frontmatter_article.update(body_markdown: new_body_markdown)
        expect(frontmatter_article.published_at).to be_within(1.minute).of(DateTime.parse(published_at))
      end

      it "keeps published at when trying to set published_at" do
        new_body_markdown = "---\ntitle: Title\npublished: false\npublished_at: 2022-05-12 18:00 +0300---\n\n"
        frontmatter_article.update(body_markdown: new_body_markdown)
        frontmatter_article.reload
        expect(frontmatter_article.published_at).to be_within(1.minute).of(DateTime.parse(published_at))
      end

      it "keeps published_at when unpublishing a scheduled article" do
        scheduled_time = 1.day.from_now
        time_str = scheduled_time.strftime("%d/%m/%Y %H:%M %z")
        scheduled_body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{time_str}\n---\n\n"
        frontmatter_scheduled_article = create(:article, body_markdown: scheduled_body_markdown)
        new_body_markdown = "---\ntitle: Title\npublished: false\n---\n\n"
        frontmatter_scheduled_article.update(body_markdown: new_body_markdown)
        frontmatter_scheduled_article.reload
        expect(frontmatter_scheduled_article.published_at).to be_within(1.minute).of(scheduled_time)
      end
    end

    context "when publishing on update (draft => published)" do
      # has published_at means that the article was published before (and unpublished later, in this)
      it "doesn't allow updating published_at if an article has already been published" do
        article.published_at = (Date.current + 10.days).strftime("%d/%m/%Y %H:%M")
        expect(article.valid?).to be false
        expect(article.errors[:published_at])
          .to include("updating published_at for articles that have already been published is not allowed")
      end

      it "allows past published_at for published_from_feed articles when publishing on update" do
        published_at = 10.days.ago
        article2 = create(:article, published: false, published_at: nil, published_from_feed: true)
        body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{published_at.strftime('%d/%m/%Y %H:%M')}
        \ndescription:\ntags: heytag\n---\n\nHey this is the article"
        article2.update(body_markdown: body_markdown)
        expect(article2.published_at).to be_within(1.minute).of(published_at)
      end

      it "doesn't allow changing published_at for published_from_feed articles that have been published before" do
        published_at = Time.current
        published_at_was = 10.days.ago
        # has published_at means that the article was published before
        article2 = create(:article, published: false, published_at: published_at_was, published_from_feed: true)
        body_markdown = "---\ntitle: Title\npublished: true\npublished_at: #{published_at.strftime('%d/%m/%Y %H:%M')}
        \ndescription:\ntags: heytag\n---\n\nHey this is the article"
        success = article2.update(body_markdown: body_markdown)
        expect(success).to be false
        expect(article2.errors[:published_at]).to include(I18n.t("models.article.immutable_published_at"))
      end
    end

    context "when updating a previously published (and unpublished) frontmatter article" do
      let(:published_at) { "2022-05-05 18:00 +0300" }
      let(:body_markdown) { "---\ntitle: Title\npublished: false\npublished_at: #{published_at}\n---\n\n" }
      let(:frontmatter_article) { create(:article, body_markdown: body_markdown) }

      it "doesn't allow updating published_at if specifying published_at" do
        # expect(frontmatter_article.published_at < 10.days.ago).to be true
        new_body_markdown = "---\ntitle: Title\npublished: true\npublished_at: 2022-10-05 18:00 +0300\n---\n\n"
        success = frontmatter_article.update(body_markdown: new_body_markdown)
        expect(success).to be false
        expect(frontmatter_article.errors[:published_at]).to include(I18n.t("models.article.immutable_published_at"))
      end

      it "doesn't allow updating published_at if removing published_at" do
        new_body_markdown = "---\ntitle: Title\npublished: true\n---\n\n"
        frontmatter_article.update(body_markdown: new_body_markdown)
        frontmatter_article.reload
        expect(frontmatter_article.published_at).to be_within(1.minute).of(DateTime.parse(published_at))
      end
    end
  end

  describe "#nth_published_by_author" do
    it "does not have a nth_published_by_author if not published" do
      unpublished_article = build(:article, published: false)
      unpublished_article.validate # to make sure the front matter extraction happens
      expect(unpublished_article.nth_published_by_author).to eq(0)
    end

    it "does have a nth_published_by_author if published" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      second_article = create(:article, user_id: published_article.user_id)
      expect(second_article.reload.nth_published_by_author).to eq(user.articles.size)
    end

    it "adds have a nth_published_by_author if published" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      second_article = create(:article, user_id: published_article.user_id)
      second_article.update_column(:nth_published_by_author, 0)
      second_article.save
      expect(second_article.reload.nth_published_by_author).to eq(user.articles.size)
    end

    it "adds have a nth_published_by_author to earlier posts if added for first time" do
      # this works because validation triggers the extraction of the date from the front matter
      published_article = create(:article, published: true, user: user)
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size)
      create(:article, user_id: published_article.user_id)
      published_article.update_column(:nth_published_by_author, 0)
      published_article.save
      expect(published_article.reload.nth_published_by_author).to eq(user.articles.size - 1)
    end
  end

  describe "#crossposted_at" do
    it "does not have crossposted_at if not published_from_feed" do
      expect(article.crossposted_at).to be_nil
    end

    it "does have crossposted_at if not published_from_feed" do
      article.update(published_from_feed: true)
      expect(article.crossposted_at).not_to be_nil
    end
  end

  describe "#slug" do
    let(:title) { "hey This' is$ a SLUG" }
    let(:article0) { build(:article, title: title, published: false) }
    let(:article1) { build(:article, title: title, published: false) }

    before do
      article0.validate!
    end

    context "when unpublished" do
      it "creates proper slug with this-is-the-slug format" do
        expect(article0.slug).to match(/(.*-){4,}/)
      end

      it "modifies slug on create if proposed slug already exists on the user" do
        article1.validate
        expect(article1.slug).not_to start_with(article0.slug)
      end

      it "properly converts underscores and still has a valid slug" do
        underscored_article = build(:article, title: "hey_hey_hey node_modules", published: false)
        expect(underscored_article.valid?).to be true
      end
    end

    context "when published" do
      before { article0.update!(published: true) }

      it "creates proper slug with this-is-the-slug format" do
        expect(article0.slug).to start_with("hey-this-is-a-slug")
      end

      it "does not change slug if the article was edited" do
        article0.update(title: "New title.")
        expect(article0.slug).to start_with("hey-this-is-a-slug")
      end

      it "properly converts underscores and still has a valid slug" do
        underscored_article = build(:article, title: "hey_hey_hey node_modules", published: true)
        expect(underscored_article.valid?).to be true
      end

      # rubocop:disable RSpec/NestedGroups
      context "with non-Roman characters" do
        let(:title) { "Я не говорю по-Русски" }

        it "converts the slug to Roman characters" do
          expect(article0.slug).to start_with("ia-nie-ghovoriu-po-russki")
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe "#username" do
    it "returns the user's username" do
      expect(article.username).to eq(user.username)
    end

    it "returns the organization slug if the article belongs to an organization" do
      article.organization = build(:organization)
      expect(article.username).to eq(article.organization.slug)
    end
  end

  describe "#has_frontmatter?" do
    it "returns true if the article has a frontmatter" do
      body = "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: hiring\n---\n\nHello"
      article.body_markdown = body
      expect(article.has_frontmatter?).to be(true)
    end

    it "returns false if the article does not have a frontmatter" do
      article.body_markdown = "Hey hey Ho Ho"
      expect(article.has_frontmatter?).to be(false)
    end

    it "returns true if parser raises a Psych::DisallowedClass error" do
      allow(FrontMatterParser::Parser).to receive(:new).and_raise(Psych::DisallowedClass.new("msg"))
      expect(article.has_frontmatter?).to be(true)
    end

    it "returns true if parser raises a Psych::SyntaxError error" do
      syntax_error = Psych::SyntaxError.new("file", 1, 1, 0, "problem", "context")
      allow(FrontMatterParser::Parser).to receive(:new).and_raise(syntax_error)
      expect(article.has_frontmatter?).to be(true)
    end
  end

  describe "#readable_edit_date" do
    it "returns nil if article is not edited" do
      expect(article.readable_edit_date).to be_nil
    end

    it "does not show year in readable time if not current year" do
      time_now = Time.current
      article.edited_at = time_now
      expect(article.readable_edit_date).to eq(I18n.l(article.edited_at, format: :short))
    end

    it "shows year in readable time if not current year" do
      article.edited_at = 1.year.ago
      last_year = 1.year.ago.year % 100
      expect(article.readable_edit_date.include?("'#{last_year}")).to be(true)
    end
  end

  describe "#readable_publish_date" do
    it "does not show year in readable time if not current year" do
      time_now = Time.current
      article.published_at = time_now
      expect(article.readable_publish_date).to eq(time_now.strftime("%b %-e"))
    end

    it "shows year in readable time if not current year" do
      article.published_at = 1.year.ago
      last_year = 1.year.ago.year % 100
      expect(article.readable_publish_date.include?("'#{last_year}")).to be(true)
    end
  end

  describe "#published_timestamp" do
    it "returns empty string if the article is not published" do
      article.published = false
      expect(article.published_timestamp).to be_empty
    end

    it "returns the timestamp of the crossposting date over the publishing date" do
      crossposted_at = 1.week.ago
      published_at = 1.day.ago
      article.published = true
      article.crossposted_at = crossposted_at
      article.published_at = published_at
      expect(article.published_timestamp).to eq(crossposted_at.utc.iso8601)
    end

    it "returns the timestamp of the publishing date if there is no crossposting date" do
      published_at = 1.day.ago
      article.published = true
      article.crossposted_at = nil
      article.published_at = published_at
      expect(article.published_timestamp).to eq(published_at.utc.iso8601)
    end
  end

  describe "#video" do
    before do
      user.created_at = 3.weeks.ago
      article.video = "https://youtube.com"
    end

    it "is not valid with a non url" do
      article.video = "hey"
      expect(article).not_to be_valid
    end

    it "is not valid if the user is too recent" do
      user.created_at = Time.current
      expect(article).not_to be_valid
    end

    it "has padded video_duration_in_minutes" do
      article.video_duration_in_seconds = 1141
      expect(article.video_duration_in_minutes).to eq("19:01")
    end

    it "has correctly non-padded seconds in video_duration_in_minutes" do
      article.video_duration_in_seconds = 1161
      expect(article.video_duration_in_minutes).to eq("19:21")
    end

    it "has video_duration_in_minutes display hour when video is an hour or longer" do
      article.video_duration_in_seconds = 3600
      expect(article.video_duration_in_minutes).to eq("1:00:00")
    end

    it "has correctly non-padded minutes with hour in video_duration_in_minutes" do
      article.video_duration_in_seconds = 5000
      expect(article.video_duration_in_minutes).to eq("1:23:20")
    end
  end

  describe "#main_image_from_frontmatter" do
    let(:article) { create(:article, user: user, main_image_from_frontmatter: false) }

    it "set to true if markdown has cover_image" do
      article = create(
        :article,
        user: user,
        body_markdown: "---\ntitle: hey\npublished: false\ncover_image: #{Faker::Avatar.image}\n---\nYo",
      )
      expect(article.main_image_from_frontmatter).to be(true)
    end

    context "when false" do
      it "does not remove main image if cover image not passed in markdown" do
        expect(article.main_image).not_to be_nil
        article.update! body_markdown: "---\ntitle: hey\npublished: false\n---\nYo ho ho#{rand(100)}"
        expect(article.reload.main_image).not_to be_nil
      end

      it "does remove main image if cover image is passed empty in markdown" do
        expect(article.main_image).not_to be_nil
        article.update! body_markdown: "---\ntitle: hey\npublished: false\ncover_image: \n---\nYo ho ho#{rand(100)}"
        expect(article.reload.main_image).to be_nil
      end
    end

    context "when true" do
      let(:article) { create(:article, main_image_from_frontmatter: true, user: user) }

      it "removes main image when cover_image not provided" do
        expect(article.main_image).not_to be_nil
        article.update! body_markdown: "---\ntitle: hey\npublished: false\n---\nYo ho ho#{rand(100)}"
        expect(article.reload.main_image).to be_nil
      end
    end
  end

  describe ".active_help" do
    it "returns properly filtered articles under the 'help' tag" do
      filtered_article = create(:article, :past, user: user, tags: "help",
                                                 past_published_at: 13.hours.ago, comments_count: 5, score: -3)
      articles = described_class.active_help
      expect(articles).to include(filtered_article)
    end

    it "returns any published articles tagged with 'help' when there are no articles that fit the criteria" do
      unfiltered_article = create(:article, :past, user: user, tags: "help",
                                                   past_published_at: 10.hours.ago, comments_count: 8, score: -5)
      articles = described_class.active_help
      expect(articles).to include(unfiltered_article)
    end
  end

  describe ".seo_boostable" do
    let!(:top_article) do
      create(:article, organic_page_views_past_month_count: 20, score: 30, tags: "good, greatalicious", user: user)
    end

    it "returns articles ordered by organic_page_views_past_month_count" do
      articles = described_class.seo_boostable
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns articles if within time frame" do
      articles = described_class.seo_boostable(nil, 1.month.ago)
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "does not return articles outside of timeframe" do
      articles = described_class.seo_boostable(nil, 1.month.from_now)
      expect(articles).to be_empty
    end

    it "returns articles ordered by organic_page_views_past_month_count by tag" do
      articles = described_class.seo_boostable("greatalicious")
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns nothing if no tagged articles" do
      articles = described_class.seo_boostable("godsdsdsdsgoo")
      expect(articles).to be_empty
    end
  end

  describe ".search_optimized_title_preamble" do
    let!(:top_article) do
      create(:article, search_optimized_title_preamble: "Hello #{rand(1000)}", tags: "good, greatalicious")
    end

    it "returns article with title preamble" do
      articles = described_class.search_optimized
      expect(articles.first[0]).to eq(top_article.path)
      expect(articles.first[1]).to eq(top_article.search_optimized_title_preamble)
    end

    it "does not return article without preamble" do
      articles = described_class.search_optimized
      new_article = create(:article)
      expect(articles.flatten).not_to include(new_article.path)
    end

    it "does return multiple articles with preamble ordered by updated_at" do
      new_article = create(:article, search_optimized_title_preamble: "Testerino")
      articles = described_class.search_optimized
      expect(articles.first[1]).to eq(new_article.search_optimized_title_preamble)
      expect(articles.second[1]).to eq(top_article.search_optimized_title_preamble)
    end

    it "returns articles ordered by organic_page_views_count by tag" do
      articles = described_class.search_optimized("greatalicious")
      expect(articles.first[0]).to eq(top_article.path)
    end

    it "returns nothing if no tagged articles" do
      articles = described_class.search_optimized("godsdsdsdsgoo")
      expect(articles).to be_empty
    end
  end

  context "when callbacks are triggered before save" do
    it "assigns path on save" do
      expect(article.path).to eq("/#{article.username}/#{article.slug}")
    end

    it "assigns cached_user_name on save" do
      expect(article.cached_user_name).to eq(article.user_name)
    end

    it "assigns cached_user_username on save" do
      expect(article.cached_user_username).to eq(article.user_username)
    end

    it "assigns cached_user on save" do
      expect(article.cached_user).to be_a(Articles::CachedEntity)
      expect(article.cached_user.name).to eq(article.user.name)
      expect(article.cached_user.username).to eq(article.user.username)
      expect(article.cached_user.slug).to eq(article.user.username)
      expect(article.cached_user.profile_image_90).to eq(article.user.profile_image_90)
      expect(article.cached_user.profile_image_url).to eq(article.user.profile_image_url)
    end

    it "assigns cached_organization on save" do
      article = create(:article, user: user, organization: create(:organization))
      expect(article.cached_organization).to be_a(Articles::CachedEntity)
      expect(article.cached_organization.name).to eq(article.organization.name)
      expect(article.cached_organization.username).to eq(article.organization.username)
      expect(article.cached_organization.slug).to eq(article.organization.slug)
      expect(article.cached_organization.profile_image_90).to eq(article.organization.profile_image_90)
      expect(article.cached_organization.profile_image_url).to eq(article.organization.profile_image_url)
    end
  end

  context "when callbacks are triggered after create" do
    describe "enrich image attributes" do
      it "enqueues Articles::EnrichImageAttributesWorker" do
        sidekiq_assert_enqueued_jobs(1, only: Articles::EnrichImageAttributesWorker) do
          build(:article).save
        end
      end
    end
  end

  context "when callbacks are triggered after save" do
    describe "article path sanitizing" do
      it "returns a downcased username when user has uppercase characters" do
        upcased_user = create(:user, username: "UpcasedUserName")
        upcased_article = create(:article, user: upcased_user)
        expect(upcased_article.path).not_to match(/[AZ]+/)
      end

      it "returns a downcased username when an org slug has uppercase characters" do
        upcased_org = create(:organization, slug: "UpcasedSlug")
        upcased_article = create(:article, organization: upcased_org)
        expect(upcased_article.path).not_to match(/[AZ]+/)
      end
    end

    describe "spam" do
      it "delegates spam handling to Spam::Handler.handle_article!" do
        allow(Spam::Handler).to receive(:handle_article!).with(article: article).and_call_original
        article.save
        expect(Spam::Handler).to have_received(:handle_article!).with(article: article)
      end
    end

    describe "record field test event" do
      it "enqueues Users::RecordFieldTestEventWorker" do
        sidekiq_assert_enqueued_with(
          job: Users::RecordFieldTestEventWorker,
          args: [article.user_id, AbExperiment::GoalConversionHandler::USER_PUBLISHES_POST_GOAL],
        ) do
          article.save
        end
      end
    end

    describe "async score calc" do
      it "enqueues Articles::ScoreCalcWorker if published" do
        sidekiq_assert_enqueued_with(job: Articles::ScoreCalcWorker, args: [article.id]) do
          article.save
        end
      end

      it "does not enqueue Articles::ScoreCalcWorker if not published" do
        article = build(:article, published: false)
        sidekiq_assert_no_enqueued_jobs(only: Articles::ScoreCalcWorker) do
          article.save
        end
      end
    end

    describe "enrich image attributes" do
      it "enqueues Articles::EnrichImageAttributesWorker if the HTML has changed" do
        sidekiq_assert_enqueued_with(job: Articles::EnrichImageAttributesWorker, args: [article.id]) do
          article.update(body_markdown: "a body")
        end
      end

      it "does not Articles::EnrichImageAttributesWorker if the HTML does not change" do
        sidekiq_assert_no_enqueued_jobs(only: Articles::EnrichImageAttributesWorker) do
          article.update(tag_list: %w[fsharp go])
        end
      end
    end
  end

  context "when triggers are invoked" do
    let(:article) { create(:article) }

    before do
      article.update(body_markdown: "An intense movie")
    end

    it "sets .reading_list_document on insert" do
      expect(article.reload.reading_list_document).to be_present
    end

    it "updates .reading_list_document with body_markdown" do
      article.update(body_markdown: "Something has changed")

      expect(article.reload.reading_list_document).to include("something")
    end

    it "updates .reading_list_document with cached_tag_list" do
      article.update(tag_list: %w[rust python])

      expect(article.reload.reading_list_document).to include("rust")
    end

    it "updates .reading_list_document with title" do
      article.update(title: "Synecdoche, Los Angeles")

      expect(article.reload.reading_list_document).to include("angeles")
    end

    it "removes a previous value from .reading_list_document on update", :aggregate_failures do
      tag = article.tags.first.name
      article.update(tag_list: %w[fsharp go])

      expect(article.reload.reading_list_document).not_to include(tag)
      expect(article.reload.reading_list_document).to include("fsharp")
    end
  end

  describe ".feed" do
    it "returns records with a subset of attributes" do
      feed_article = described_class.feed.first

      fields = %w[id tag_list published_at processed_html user_id organization_id title path cached_tag_list]
      expect(feed_article.attributes.keys).to match_array(fields)
    end
  end

  describe "collection cleanup" do
    let(:collection) { create(:collection, title: "test series") }
    let(:article) { create(:article, with_collection: collection) }

    it "destroys the collection if collection is empty" do
      expect do
        article.body_markdown.gsub!("series: #{collection.slug}", "")
        article.save
      end.to change(Collection, :count).by(-1)
    end

    it "avoids destroying the collection if the collection has other articles" do
      expect do
        create(:article, user: user, with_collection: collection)
        article.body_markdown.gsub!("series: #{collection.slug}", "")
        article.save
      end.not_to change(Collection, :count)
    end
  end

  describe "#top_comments" do
    context "when article has comments" do
      let(:root_comment) { create(:comment, commentable: article, score: 20) }
      let(:child_comment) { create(:comment, commentable: article, score: 20, parent: root_comment) }
      let(:hidden_comment) { create(:comment, commentable: article, score: 20, hidden_by_commentable_user: true) }
      let(:deleted_comment) { create(:comment, commentable: article, score: 20, deleted: true) }

      before do
        root_comment
        child_comment
        hidden_comment
        deleted_comment
        create_list(:comment, 2, commentable: article, score: 20)
        article.reload
      end

      it "returns comments with score greater than 10" do
        expect(article.top_comments.first.score).to be > 10
      end

      it "only includes root comments" do
        expect(article.top_comments).not_to include(child_comment)
      end

      it "doesn't include hidden comments" do
        expect(article.top_comments).not_to include(hidden_comment)
      end

      it "doesn't include deleted comments" do
        expect(article.top_comments).not_to include(deleted_comment)
      end
    end

    context "when article does not have any comments" do
      it "returns empty set if there aren't any top comments" do
        expect(article.top_comments).to be_empty
      end
    end
  end

  describe "co_author_ids_list=" do
    it "correctly sets co author ids from a comma separated list of ids" do
      co_author1 = create(:user)
      co_author2 = create(:user)
      article.co_author_ids_list = "#{co_author1.id}, #{co_author2.id}"
      expect(article.co_author_ids).to contain_exactly(co_author1.id, co_author2.id)
    end
  end

  describe "#plain_html" do
    let(:body_markdown) do
      <<~MD
        ---
        title: Test highlight panel
        published: false
        ---

        text before

          ```ruby
          def foo():
            puts "bar"
          ```

        text after
      MD
    end

    it "doesn't include highlight panel markup" do
      article = create(:article, body_markdown: body_markdown)

      expect(article.plain_html).to include("text before")
      expect(article.plain_html).to include("highlight")
      expect(article.plain_html).not_to include("highlight__panel")
    end
  end

  describe "#user_mentions_in_markdown" do
    before do
      stub_const("Article::MAX_USER_MENTION_LIVE_AT", 1.day.ago) # Set live_at date to a time in the past
    end

    it "is valid with any number of mentions if created before MAX_USER_MENTION_LIVE_AT date" do
      # Explicitly set created_at date to a time before MAX_USER_MENTION_LIVE_AT
      article = create(:article, created_at: 3.days.ago)

      article.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
      expect(article).to be_valid
    end

    it "is valid with seven or fewer mentions if created after MAX_USER_MENTION_LIVE_AT date" do
      article.body_markdown = "hi @#{user.username}! " * Settings::RateLimit.mention_creation
      expect(article).to be_valid
    end

    it "is invalid with more than seven mentions if created after MAX_USER_MENTION_LIVE_AT date" do
      article.body_markdown = "hi @#{user.username}! " * (Settings::RateLimit.mention_creation + 1)
      expect(article).not_to be_valid
      expect(article.errors[:base])
        .to include("You cannot mention more than #{Settings::RateLimit.mention_creation} users in a post!")
    end
  end

  describe "#followers" do
    it "returns an array of users who follow the article's author" do
      following_user = create(:user)
      following_user.follow(user)

      expect(article.followers.length).to eq(1)
    end
  end

  describe "#update_score" do
    it "stably sets the correct blackbox values" do
      create(:reaction, reactable: article, points: 1)

      article.update_score
      expect { article.update_score }.not_to change { article.reload.hotness_score }
    end

    it "caches the privileged score values" do
      user = create(:user, :trusted)

      create(:thumbsdown_reaction, reactable: article, user: user)

      expect { article.update_score }.to change { article.reload.privileged_users_reaction_points_sum }
    end
  end

  describe "#feed_source_url and canonical_url must be unique for published articles" do
    let(:url) { "http://www.example.com" }

    it "is valid when both articles are drafts" do
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is valid when first article is a draft, second is published" do
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is valid when first article is published, second is draft" do
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      body_markdown = "---\ntitle: Title\npublished: false\ncanonical_url: #{url}\n---\n\n"
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)

      expect(another_article).to be_valid
    end

    it "is not valid when both articles are published" do
      body_markdown = "---\ntitle: Title\npublished: true\ncanonical_url: #{url}\n---\n\n"
      create(:article, body_markdown: body_markdown, feed_source_url: url)
      another_article = build(:article, body_markdown: body_markdown, feed_source_url: url)
      error_message = "has already been taken. " \
                      "Email #{ForemInstance.contact_email} for further details."
      expect(another_article).not_to be_valid
      expect(another_article.errors.messages[:canonical_url]).to include(error_message)
      expect(another_article.errors.messages[:feed_source_url]).to include(error_message)
    end
  end

  describe "#public_reaction_categories reports unique associated reaction categories" do
    before do
      user2 = create(:user)
      user2.add_role(:trusted)

      create(:reaction, reactable: article, category: "like")
      create(:reaction, reactable: article, category: "like")
      create(:reaction, reactable: article, category: "readinglist")
      create(:reaction, reactable: article, category: "vomit", user: user2)
    end

    it "reports accurately" do
      categories = article.public_reaction_categories
      expect(categories.map(&:slug)).to match_array(%i[like])
    end
  end

  describe ".above_average and .average_score" do
    before do
      create(:article, score: 10)
      create(:article, score: 6)
      create(:article, score: 4)
      create(:article, score: 1)
      # averages 4.2
    end

    it "works as expected" do
      expect(described_class.average_score).to be_within(0.1).of(4.2)
      articles = described_class.above_average
      expect(articles.pluck(:score)).to contain_exactly(10, 6)
    end
  end
end
