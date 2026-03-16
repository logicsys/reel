require 'spec_helper'

RSpec.describe Reel::Request::Parser do
  describe "error message sanitization" do
    it "does not include raw user input in Transfer-Encoding error messages" do
      # Simulate a malicious Transfer-Encoding value that could be used for
      # log injection or XSS if the error message is rendered in HTML
      headers = {
        "Host" => "example.com",
        "Transfer-Encoding" => "<script>alert('xss')</script>"
      }

      parser = nil
      with_socket_pair do |client, peer|
        connection = Reel::Connection.new(peer)
        parser = connection.parser
      end

      expect {
        parser.send(:validate_headers!, headers)
      }.to raise_error(Reel::RequestError) { |error|
        expect(error.message).not_to include("<script>")
        expect(error.message).not_to include("alert")
      }
    end

    it "still rejects invalid Transfer-Encoding values" do
      headers = {
        "Host" => "example.com",
        "Transfer-Encoding" => "bogus-encoding"
      }

      parser = nil
      with_socket_pair do |client, peer|
        connection = Reel::Connection.new(peer)
        parser = connection.parser
      end

      expect {
        parser.send(:validate_headers!, headers)
      }.to raise_error(Reel::RequestError, /Invalid Transfer-Encoding/)
    end

    it "accepts valid Transfer-Encoding values" do
      headers = {
        "Host" => "example.com",
        "Transfer-Encoding" => "chunked"
      }

      parser = nil
      with_socket_pair do |client, peer|
        connection = Reel::Connection.new(peer)
        parser = connection.parser
      end

      expect {
        parser.send(:validate_headers!, headers)
      }.not_to raise_error
    end
  end
end
