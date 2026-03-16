require 'spec_helper'

RSpec.describe Reel::Connection do
  describe "#hijack_socket" do
    it "checks request FSM state correctly using .state method" do
      source = File.read(File.expand_path("../../../lib/reel/connection.rb", __FILE__))

      # The guard should use @request_fsm.state, not compare the FSM object
      # directly to a symbol (which always evaluates to true)
      expect(source).not_to match(/@request_fsm\s*!=\s*:/),
        "hijack_socket compares StateMachine object directly to symbol — " \
        "should use @request_fsm.state instead"
    end

    it "raises StateError when connection is in closed state" do
      with_socket_pair do |client, peer|
        connection = Reel::Connection.new(peer)

        # Force the connection into a non-hijackable state
        # by transitioning through to closed
        connection.instance_variable_get(:@request_fsm).transition(:closed)
        connection.instance_variable_set(:@response_state, :closed)

        expect {
          connection.hijack_socket
        }.to raise_error(Reel::StateError, /not in a hijackable state/)
      end
    end
  end
end
