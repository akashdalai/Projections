require "rails_helper"

RSpec.describe "Tracking 'Clicked on Create Account'", :js do
  context "when on the homepage" do
    before do
      user = create(:user)
      create_list(:article, 6, user: user)
      visit root_path
    end

    it "has the necessary initial tracking elements", :aggregate_failures do
      expect(page).to have_css('a[data-tracking-id="ca_top_nav"]')
      expect(page).to have_css('a[data-tracking-id="ca_left_sidebar_home_page"]')
    end

    it "has the create account tracking element in the hamburger", :aggregate_failures do
      Capybara.current_session.driver.resize(425, 694)
      first(".js-hamburger-trigger").click
      # expect /message route to receive a request
      expect(page).to have_css('a[data-tracking-id="ca_hamburger_home_page"]')
    end

    it "tracks a click with the correct source", :aggregate_failures do
      allow(Ahoy::EventsController).to receive(:new).and_call_original
      find('[data-tracking-id="ca_top_nav"]').click
      expect(Ahoy::EventsController).to have_received(:new).once
      expect(Ahoy::Event.count).to eq(1)

      expect(Ahoy::Event.last.name).to eq("Clicked on Create Account")
      expect(Ahoy::Event.last.properties).to include("source", "page", "version", "source" => "top_navbar")
    end
  end

  context "when tracking through the modal" do
    it "adds an ahoy event", :aggregate_failures do
      allow(Ahoy::EventsController).to receive(:new).and_call_original
      article = create(:article, user: create(:user))
      visit article.path
      expect(Ahoy::Event.count).to eq(0)
      find(".follow-action-button").click
      find(".js-global-signup-modal__create-account").click

      expect(Ahoy::EventsController).to have_received(:new).once

      expect(page).to have_current_path("/enter?state=new-user")
      expect(Ahoy::Event.last.name).to eq("Clicked on Create Account")
      expect(Ahoy::Event.last.properties).to include("source", "page", "referring_source", "trigger", "version")
    end
  end
end
