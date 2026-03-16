require 'spec_helper'

RSpec.describe "HTTP Request Smuggling Security" do
  def with_reel(handler)
    host = "127.0.0.1"
    port = 12345  # Use a different port than the main tests to avoid conflicts
    server = Reel::Server::HTTP.new(host, port, &handler)
    begin
      yield TCPSocket.new(host, port), server
    ensure
      server.terminate if server && server.alive?
    end
  end

  # Read the full response from the server, handling both graceful close and reset
  def read_response(client)
    client.close_write
    response = ""
    begin
      loop do
        response << client.readpartial(4096)
      end
    rescue EOFError, Errno::ECONNRESET
      # Connection closed by server
    end
    response
  end

  describe "Content-Length header validation" do
    it "rejects requests with duplicate Content-Length headers" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: 10",
          "Content-Length: 5",
          "",
          "test data"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "rejects requests with invalid Content-Length values" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: -5",
          "",
          "test"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "rejects requests with non-numeric Content-Length values" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: abc",
          "",
          "test"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end
  end

  describe "Transfer-Encoding header validation" do
    it "rejects requests with invalid Transfer-Encoding values" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Transfer-Encoding: malicious-encoding",
          "",
          "test data"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "rejects requests where chunked is not the final encoding" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Transfer-Encoding: chunked",
          "Transfer-Encoding: gzip",
          "",
          "test data"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "accepts valid Transfer-Encoding values" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        valid_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Transfer-Encoding: identity",
          "Content-Length: 5",
          "Connection: close",
          "",
          "hello"
        ].join("\r\n")

        client.write(valid_request)
        response = ""
        begin
          loop { response << client.readpartial(4096) }
        rescue EOFError, Errno::ECONNRESET
        end
        expect(response).to include("200 OK")
      end
    end
  end

  describe "Content-Length and Transfer-Encoding conflict" do
    it "rejects requests with both Content-Length and Transfer-Encoding: chunked" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        malicious_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: 10",
          "Transfer-Encoding: chunked",
          "",
          "5\r\nhello\r\n0\r\n\r\n"
        ].join("\r\n")

        client.write(malicious_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "allows Content-Length without Transfer-Encoding" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        valid_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: 5",
          "Connection: close",
          "",
          "hello"
        ].join("\r\n")

        client.write(valid_request)
        response = ""
        begin
          loop { response << client.readpartial(4096) }
        rescue EOFError, Errno::ECONNRESET
        end
        expect(response).to include("200 OK")
      end
    end
  end

  describe "HTTP request smuggling attack prevention" do
    it "prevents CL.TE smuggling attacks" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        smuggling_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Content-Length: 6",
          "Transfer-Encoding: chunked",
          "",
          "0\r\n\r\n"
        ].join("\r\n")

        client.write(smuggling_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end

    it "prevents TE.CL smuggling attacks" do
      with_reel(proc { |connection| connection.request; connection.respond :ok, "Hello World" }) do |client, server|
        smuggling_request = [
          "POST / HTTP/1.1",
          "Host: example.com",
          "Transfer-Encoding: xchunked",
          "Content-Length: 4",
          "",
          "test"
        ].join("\r\n")

        client.write(smuggling_request)
        response = read_response(client)
        expect(response).not_to include("200 OK")
      end
    end
  end
end
