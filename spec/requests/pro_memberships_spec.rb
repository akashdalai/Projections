require "rails_helper"

RSpec.describe "Pro Memberships", type: :request do
  describe "GET /pro" do
    it "returns pro lander" do
      get pro_membership_path
      expect(response.body).to include("Like a Pro")
    end
  end

  describe "POST /pro" do
    let(:user) { create(:user) }

    context "when the user is not logged in" do
      it "redirects to the sign up page" do
        post pro_membership_path
        expect(response).to redirect_to(sign_up_path)
      end
    end

    context "when the user is logged in and already has a pro memberships" do
      before do
        sign_in user
      end

      it "does not authorize creation if it has an active membership" do
        create(:pro_membership, user: user)
        expect do
          post pro_membership_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not authorize creation if it has an expired membership" do
        create(:pro_membership, :expired, user: user)
        expect do
          post pro_membership_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when the user is logged in without a pro membership and enough credits" do
      before do
        sign_in user
        create_list(:credit, ProMembership::MONTHLY_COST, user: user)
      end

      it "creates an active pro membership" do
        expect do
          post pro_membership_path
        end.to change(ProMembership, :count).by(1)
        expect(user.reload.pro_membership.active?).to be(true)
      end

      it "buys the pro membership with the correct amount of credits" do
        expect do
          post pro_membership_path
        end.to change(user.credits.spent, :count).by(ProMembership::MONTHLY_COST)
      end

      it "enqueues a job to populate the history" do
        assert_enqueued_with(
          job: ProMemberships::PopulateHistoryJob,
          args: [user.id],
          queue: "pro_memberships_populate_history",
        ) do
          post pro_membership_path
        end
      end

      it "redirects to the show page with a notice" do
        post pro_membership_path
        expect(response).to redirect_to(pro_membership_path)
        expect(flash[:notice]).to eq("You are now a Pro!")
      end
    end

    context "when the user is logged in without a pro membership and not enough credits" do
      before do
        sign_in user
      end

      it "does not create an active pro membership" do
        expect do
          post pro_membership_path
        end.to change(ProMembership, :count).by(0)
      end

      it "does not subtract credits" do
        expect do
          post pro_membership_path
        end.to change(user.credits.spent, :count).by(0)
      end

      it "redirects to the show page with an error message" do
        post pro_membership_path
        expect(response).to redirect_to(pro_membership_path)
        expect(flash[:error]).to eq("You don't have enough credits!")
      end
    end
  end
end
