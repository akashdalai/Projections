require "rails_helper"

RSpec.describe PollOption, type: :model do
  let_it_be(:article) { build(:article, featured: true) }
  let_it_be(:poll) { build(:poll, article: article) }
  let_it_be(:poll_option) { build(:poll_option, poll: poll) }

  describe "validations" do
    describe "builtin validations" do
      subject { poll_option }

      it { is_expected.to belong_to(:poll) }
      it { is_expected.to have_many(:poll_votes).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:markdown) }
    end

    it "allows up to 128 markdown characters" do
      poll_option.markdown = "0" * 128
      expect(poll_option).to be_valid
    end

    it "disallows over 128 markdown characters" do
      poll_option.markdown = "0" * 129
      expect(poll_option).not_to be_valid
    end
  end
end
