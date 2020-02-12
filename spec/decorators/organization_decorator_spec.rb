require "rails_helper"

RSpec.describe OrganizationDecorator, type: :decorator do
  describe "#darker_color" do
    it "returns a darker version of the assigned color if colors are blank" do
      organization = build(:organization, bg_color_hex: "", text_color_hex: "")
      expect(organization.decorate_.darker_color).to eq("#090909")
    end

    it "returns a darker version of the color if bg_color_hex is present" do
      organization = build(:organization, bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(organization.decorate_.darker_color).to eq("#c2c2c2")
    end

    it "returns an adjusted darker version of the color" do
      organization = build(:organization, bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(organization.decorate_.darker_color(0.3)).to eq("#424242")
    end

    it "returns an adjusted lighter version of the color if adjustment is over 1.0" do
      organization = build(:organization, bg_color_hex: "#dddddd", text_color_hex: "#ffffff")
      expect(organization.decorate_.darker_color(1.1)).to eq("#f3f3f3")
    end
  end

  describe "#enriched_colors" do
    it "returns the assigned colors if bg_color_hex is blank" do
      organization = build(:organization, bg_color_hex: "")
      expect(organization.decorate_.enriched_colors).to eq(bg: "#0a0a0a", text: "#ffffff")
    end

    it "returns bg_color_hex and assigned text_color_hex if text_color_hex is blank" do
      organization = build(:organization, bg_color_hex: "#dddddd", text_color_hex: "")
      expect(organization.decorate_.enriched_colors).to eq(bg: "#dddddd", text: "#ffffff")
    end

    it "returns bg_color_hex and text_color_hex" do
      organization = build(:organization, bg_color_hex: "#dddddd", text_color_hex: "#fffff3")
      expect(organization.decorate_.enriched_colors).to eq(bg: "#dddddd", text: "#fffff3")
    end
  end

  describe "#assigned_color" do
    it "returns the default assigned colors" do
      organization = build(:organization)
      expect(organization.decorate_.assigned_color).to eq(bg: "#0a0a0a", text: "#ffffff")
    end
  end

  describe "#fully_banished?" do
    it "returns false" do
      organization = build(:organization)
      expect(organization.decorate_.fully_banished?).to be(false)
    end
  end
end
