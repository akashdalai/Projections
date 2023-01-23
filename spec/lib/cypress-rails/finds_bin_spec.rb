require "rails_helper"

require_dependency Rails.root.join("lib/cypress-rails/finds_bin.rb")

RSpec.describe CypressRails::FindsBin do
  describe ".call" do
    it "finds the bin file" do
      expect(described_class.new.call).to eq("node_modules/.bin/cypress")
    end

    it "finds the bin file when the bin is not in the default location" do
      allow(ENV).to receive(:[]).with("KNAPSACK_PRO_CI_NODE_TOTAL").and_return("1")
      allow(ENV).to receive(:[]).with("KNAPSACK_PRO_CI_NODE_INDEX").and_return("1")
      expect(described_class.new.call).to eq("node_modules/.bin/knapsack-pro-cypress")
    end
  end
end
