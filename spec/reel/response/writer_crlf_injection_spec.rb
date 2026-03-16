require 'spec_helper'

RSpec.describe "CRLF injection protection" do
  describe "Response sanitizes header values at construction" do
    it "strips CRLF sequences from header values" do
      malicious_value = "safe-value\r\nX-Injected: evil"
      response = Reel::Response.new(:ok, {"X-Custom" => malicious_value}, "hello")
      expect(response.headers["X-Custom"]).to eq("safe-valueX-Injected: evil")
      expect(response.headers["X-Injected"]).to be_nil
    end

    it "strips bare LF from header values" do
      malicious_value = "safe-value\nX-Injected: evil"
      response = Reel::Response.new(:ok, {"X-Custom" => malicious_value}, "hello")
      expect(response.headers["X-Custom"]).to eq("safe-valueX-Injected: evil")
      expect(response.headers["X-Injected"]).to be_nil
    end

    it "strips bare CR from header values" do
      malicious_value = "safe-value\rX-Injected: evil"
      response = Reel::Response.new(:ok, {"X-Custom" => malicious_value}, "hello")
      expect(response.headers["X-Custom"]).to eq("safe-valueX-Injected: evil")
    end

    it "preserves clean header values" do
      response = Reel::Response.new(:ok, {"X-Custom" => "perfectly-fine"}, "hello")
      expect(response.headers["X-Custom"]).to eq("perfectly-fine")
    end
  end

  describe "Response::Writer cannot write injected headers" do
    it "renders sanitized headers to the socket" do
      with_socket_pair do |socket, peer|
        writer = Reel::Response::Writer.new(socket)

        # Even if someone bypasses Response and sets headers directly,
        # the writer also sanitizes
        malicious_value = "safe-value\r\nX-Injected: evil"
        response = Reel::Response.new(:ok, {"X-Custom" => malicious_value}, "hello")
        writer.handle_response(response)

        raw = peer.readpartial(4096)
        header_lines = raw.split("\r\n")
        injected = header_lines.any? { |line| line =~ /^X-Injected:/i }
        expect(injected).to be false
        expect(raw).to include("X-Custom: safe-valueX-Injected: evil")
      end
    end

    it "passes through clean headers unchanged" do
      with_socket_pair do |socket, peer|
        writer = Reel::Response::Writer.new(socket)

        response = Reel::Response.new(:ok, {"X-Custom" => "perfectly-fine"}, "hello")
        writer.handle_response(response)

        raw = peer.readpartial(4096)
        expect(raw).to include("X-Custom: perfectly-fine")
      end
    end
  end

  describe "header names are protected by the HTTP gem" do
    it "rejects header names containing CRLF" do
      malicious_name = "X-Custom\r\nX-Injected: evil\r\nX-Another"
      expect {
        Reel::Response.new(:ok, {malicious_name => "value"}, "hello")
      }.to raise_error(HTTP::HeaderError)
    end
  end
end
