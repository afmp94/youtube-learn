module Quotes
  class Extractor
    def initialize(video_learning)
      @video_learning = video_learning
    end

    def call
      unless @video_learning.transcript_text.present?
        raise Quotes::ExtractionError, "No transcript available for quote extraction"
      end

      quotes_data = extract_quotes_from_claude
      create_quotes(quotes_data)
    end

    private

    def extract_quotes_from_claude
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
      raise Quotes::ExtractionError, "Anthropic API key not configured" if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      content_blocks = build_content_blocks

      response = client.messages.create(
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 4096,
        system: system_prompt,
        messages: [{ role: "user", content: content_blocks }]
      )

      result_text = if response.respond_to?(:content)
        block = response.content.is_a?(Array) ? response.content.first : response.content
        block.respond_to?(:text) ? block.text : block["text"]
      else
        response.dig("content", 0, "text")
      end

      parse_response(result_text)
    rescue Quotes::ExtractionError
      raise
    rescue JSON::ParserError => e
      raise Quotes::ExtractionError, "Failed to parse Claude response: #{e.message}"
    rescue => e
      raise Quotes::ExtractionError, "Quote extraction failed: #{e.message}"
    end

    def system_prompt
      <<~PROMPT
        Extract 5-15 notable, memorable, or insightful quotes from this video transcript. For each quote, provide: the exact text, the speaker (if identifiable from context), approximate timestamp (if determinable from transcript data), and brief context about what was being discussed.

        Focus on quotes that are:
        - Thought-provoking or inspiring
        - Key insights or revelations
        - Memorable phrases or analogies
        - Important conclusions or recommendations
        - Controversial or surprising statements

        Output valid JSON as an array with this exact structure:
        [
          {
            "text": "The exact quote text from the transcript",
            "speaker": "Speaker name or null if unknown",
            "timestamp_seconds": 123.4,
            "context": "Brief context about what was being discussed when this was said"
          }
        ]

        Important:
        - Use the EXACT words from the transcript, do not paraphrase
        - If the speaker cannot be identified, use the channel name or null
        - If timestamp cannot be determined, use null
        - Return ONLY the JSON array, no other text
      PROMPT
    end

    def build_content_blocks
      blocks = []

      # Include timestamped transcript data if available for accurate timestamps
      if @video_learning.transcript_data.present?
        transcript_with_times = @video_learning.transcript_data.map do |entry|
          "[#{format_seconds(entry["start"] || entry[:start])}] #{entry["text"] || entry[:text]}"
        end.join("\n")

        blocks << {
          type: "text",
          text: "TIMESTAMPED TRANSCRIPT:\n\n#{transcript_with_times.truncate(80_000)}"
        }
      else
        blocks << {
          type: "text",
          text: "VIDEO TRANSCRIPT:\n\n#{@video_learning.transcript_text.truncate(80_000)}"
        }
      end

      blocks << {
        type: "text",
        text: "VIDEO INFO:\nTitle: #{@video_learning.title}\nChannel: #{@video_learning.channel_name}"
      }

      blocks
    end

    def format_seconds(seconds)
      return "0:00" unless seconds
      s = seconds.to_f
      minutes = (s / 60).to_i
      secs = (s % 60).to_i
      format("%d:%02d", minutes, secs)
    end

    def parse_response(text)
      json_text = if text.include?("```")
        text.gsub(/\A.*?```(?:json)?\s*\n/m, "").gsub(/\n?\s*```.*\z/m, "")
      else
        text
      end.strip

      begin
        data = JSON.parse(json_text)
      rescue JSON::ParserError
        repaired = json_text
        repaired += '"' if repaired.count('"').odd?
        open_brackets = repaired.count("[") - repaired.count("]")
        open_braces = repaired.count("{") - repaired.count("}")
        repaired += "}" * open_braces if open_braces > 0
        repaired += "]" * open_brackets if open_brackets > 0
        data = JSON.parse(repaired)
      end

      # Handle both array and object with quotes key
      data = data["quotes"] if data.is_a?(Hash) && data["quotes"]

      raise Quotes::ExtractionError, "Expected an array of quotes" unless data.is_a?(Array)

      data
    end

    def create_quotes(quotes_data)
      # Remove existing quotes for this video to avoid duplicates on re-extraction
      @video_learning.quotes.destroy_all

      quotes = quotes_data.map do |q|
        @video_learning.quotes.create!(
          text: q["text"],
          speaker: q["speaker"].presence || @video_learning.channel_name,
          timestamp_seconds: q["timestamp_seconds"]&.to_f,
          context: q["context"]
        )
      end

      quotes
    end
  end
end
