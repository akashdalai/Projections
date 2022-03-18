require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service, vcr: true do
  let(:badge) { create(:badge, title: "DEV Contributor") }

  before do
    badge
    omniauth_mock_github_payload
    stub_const("#{described_class}::REPOSITORIES", ["forem/DEV-Android"])
  end

  it "awards contributor badge" do
    user = create(:user, :with_identity, identities: ["github"], uid: "389169")

    Timecop.freeze("2021-08-16T13:49:20Z") do
      expect do
        VCR.use_cassette("github_client_commits_contributor_badge") do
          described_class.call
        end
      end.to change(user.badge_achievements, :count).by(1)
    end
  end

  it "awards contributor badge once" do
    user = create(:user, :with_identity, identities: ["github"], uid: "389169")
    Timecop.freeze("2021-08-16T13:49:20Z") do
      expect do
        VCR.use_cassette("github_client_commits_contributor_badge_twice") do
          described_class.call
          described_class.call
        end
      end.to change(user.badge_achievements, :count).by(1)
    end
  end

  it "awards bronze contributor badge" do
    badge = create(:badge, title: "4x Commit Club")
    user = create(:user, :with_identity, identities: ["github"], uid: "459464")
    Timecop.freeze("2021-08-16T13:49:20Z") do
      VCR.use_cassette("github_client_commits_contributor_badge") do
        expect do
          described_class.call
        end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
      end
    end
  end

  it "awards silver contributor badge" do
    badge = create(:badge, title: "8x Commit Club")
    user = create(:user, :with_identity, identities: ["github"], uid: "6045239")
    Timecop.freeze("2021-08-16T13:49:20Z") do
      VCR.use_cassette("github_client_commits_contributor_badge") do
        expect do
          described_class.call
        end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
      end
    end
  end

  it "awards gold contributor badge" do
    badge = create(:badge, title: "16x-commit-club")
    user = create(:user, :with_identity, identities: ["github"], uid: "15793250")

    Timecop.freeze("2021-08-16T13:49:20Z") do
      VCR.use_cassette("github_client_commits_contributor_badge") do
        expect do
          described_class.call
        end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
      end
    end
  end

  it "awards single commit contributors" do
    stub_const("#{described_class}::REPOSITORIES", ["forem/forem"])
    user = create(:user, :with_identity, identities: ["github"], uid: "49699333")
    Timecop.freeze("2021-08-16T13:49:20Z") do
      VCR.use_cassette("awards_single_commit_contributors") do
        expect do
          described_class.call
        end.to change(user.badge_achievements, :count).by(1)
      end
    end
  end
end
