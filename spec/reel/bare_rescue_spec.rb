require 'spec_helper'

RSpec.describe "Bare rescue clause safety" do
  describe "Reel::Request::Body#to_str" do
    it "uses explicit StandardError rescue instead of bare rescue" do
      source = File.read(File.expand_path("../../../lib/reel/request/body.rb", __FILE__))

      # Should not contain bare "rescue" without an exception class
      # A bare rescue on its own line (not rescue SomeError) catches StandardError
      # but is considered bad practice and can mask bugs
      bare_rescue_lines = source.lines.select { |line| line.strip =~ /\Arescue\s*$/ }
      expect(bare_rescue_lines).to be_empty,
        "body.rb contains bare rescue clause(s) — should specify exception class explicitly"
    end
  end

  describe "Reel::WebSocket#write" do
    it "uses explicit StandardError rescue instead of bare rescue" do
      source = File.read(File.expand_path("../../../lib/reel/websocket.rb", __FILE__))

      bare_rescue_lines = source.lines.select { |line| line.strip =~ /\Arescue\s*$/ }
      expect(bare_rescue_lines).to be_empty,
        "websocket.rb contains bare rescue clause(s) — should specify exception class explicitly"
    end
  end
end
