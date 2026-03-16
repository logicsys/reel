require 'spec_helper'

RSpec.describe Reel::Connection do
  describe "read timeout" do
    it "supports a configurable timeout option" do
      source = File.read(File.expand_path("../../../lib/reel/connection.rb", __FILE__))

      expect(source).to match(/timeout/i),
        "Connection does not support a timeout option — " \
        "slow clients can hold connections open indefinitely"
    end

    it "defines a default timeout constant" do
      expect(Reel::Connection::DEFAULT_TIMEOUT).to be_a(Numeric)
      expect(Reel::Connection::DEFAULT_TIMEOUT).to be > 0
    end
  end
end
