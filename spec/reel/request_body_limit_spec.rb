require 'spec_helper'

RSpec.describe Reel::Request::Body do
  # Create a mock request that yields chunks
  let(:chunks) { ["a" * 1024] * 10 } # 10KB total
  let(:mock_request) do
    req = Object.new
    chunks_iter = chunks.each
    req.define_singleton_method(:readpartial) do |*|
      begin
        chunks_iter.next
      rescue StopIteration
        nil
      end
    end
    req
  end

  describe "#to_str with max_body_size" do
    it "raises an error when body exceeds max_body_size" do
      body = described_class.new(mock_request, max_body_size: 5000) # 5KB limit
      expect { body.to_str }.to raise_error(Reel::RequestError, /body size exceeds/)
    end

    it "reads body fully when under max_body_size" do
      body = described_class.new(mock_request, max_body_size: 20_000) # 20KB limit
      expect(body.to_str.bytesize).to eq(10_240)
    end

    it "reads body fully when no max_body_size is set" do
      body = described_class.new(mock_request)
      expect(body.to_str.bytesize).to eq(10_240)
    end
  end

  describe "default MAX_BODY_SIZE constant" do
    it "defines a sensible default maximum body size" do
      expect(Reel::Request::Body::DEFAULT_MAX_BODY_SIZE).to be_a(Integer)
      expect(Reel::Request::Body::DEFAULT_MAX_BODY_SIZE).to be > 0
    end
  end
end
