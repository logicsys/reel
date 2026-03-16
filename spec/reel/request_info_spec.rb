require 'spec_helper'

RSpec.describe Reel::Request::Info do
  let(:headers) do
    {
      "Content-Type"   => "text/html",
      "X-Custom"       => "secret-value",
      "Authorization"  => "Bearer token123"
    }
  end

  let(:info) { described_class.new("GET", "/test", "HTTP/1.1", headers) }

  describe "case-insensitive header lookup" do
    it "finds headers regardless of case" do
      expect(info.headers["content-type"]).to eq("text/html")
      expect(info.headers["CONTENT-TYPE"]).to eq("text/html")
      expect(info.headers["Content-Type"]).to eq("text/html")
    end
  end

  describe "regex injection via header key lookup" do
    it "does not allow wildcard regex patterns to match arbitrary headers" do
      # An attacker passing ".*" as a header key should NOT match all headers
      result = info.headers[".*"]
      expect(result).to be_nil
    end

    it "does not allow regex character classes to match unrelated headers" do
      # "[ACXZ]" should not be interpreted as a regex character class
      result = info.headers["[ACXZ]"]
      expect(result).to be_nil
    end

    it "does not allow regex alternation to extract other headers" do
      # "Content-Type|Authorization" should not match either header
      result = info.headers["Content-Type|Authorization"]
      expect(result).to be_nil
    end

    it "does not cause ReDoS with pathological patterns" do
      # This pattern causes catastrophic backtracking if interpreted as regex
      require 'timeout'
      expect {
        Timeout.timeout(1) do
          info.headers["(a+)+$"]
        end
      }.not_to raise_error
    end

    it "handles literal special regex characters in header names" do
      special_headers = { "X-Rate.Limit" => "100" }
      special_info = described_class.new("GET", "/", "HTTP/1.1", special_headers)
      # Should find "X-Rate.Limit" literally, not "X-Rate" + any char + "Limit"
      expect(special_info.headers["X-Rate.Limit"]).to eq("100")
      # "X-RateXLimit" should NOT match (the dot should be literal)
      expect(special_info.headers["X-RateXLimit"]).to be_nil
    end
  end
end
