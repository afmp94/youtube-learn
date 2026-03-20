require "net/http"
require "json"

module Embeddings
  class Generator
    MODEL = "nomic-embed-text"
    DIMENSIONS = 768

    def initialize
      @base_url = ENV.fetch("OLLAMA_URL", "http://localhost:11434")
    end

    def generate(text)
      body = { model: MODEL, input: truncate(text) }
      response = post("/api/embed", body)
      response["embeddings"]&.first
    end

    def generate_batch(texts)
      truncated = texts.map { |t| truncate(t) }
      body = { model: MODEL, input: truncated }
      response = post("/api/embed", body)
      response["embeddings"] || []
    end

    private

    def post(path, body)
      uri = URI("#{@base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body)

      response = http.request(request)
      raise "Ollama error (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def truncate(text)
      text.to_s[0...8000]
    end
  end
end
